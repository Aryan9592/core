// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {FollowNFTProxy} from '../upgradeability/FollowNFTProxy.sol';
import {Helpers} from './Helpers.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {ICollectNFT} from '../interfaces/ICollectNFT.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

import './Constants.sol';

/**
 * @title InteractionLogic
 * @author Lens Protocol
 *
 * @notice This is the library that contains the logic for follows & collects. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library InteractionHelpers {
    using Strings for uint256;

    function follow(
        address follower,
        uint256[] calldata profileIds,
        bytes[] calldata followModuleDatas //,
    ) internal returns (uint256[] memory) {
        if (profileIds.length != followModuleDatas.length) revert Errors.ArrayMismatch();
        uint256[] memory tokenIds = new uint256[](profileIds.length);

        for (uint256 i = 0; i < profileIds.length; ) {
            uint256 profileId = profileIds[i];
            _validateProfileExistsViaHandle(profileId);
            uint256 followNFTSlot;
            address followModule;
            address followNFT;
            assembly {
                mstore(0, profileId)
                mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
                // The follow NFT offset is 2, the follow module offset is 1,
                // so we just need to subtract 1 instead of recalculating the slot.
                followNFTSlot := add(keccak256(0, 64), PROFILE_FOLLOW_NFT_OFFSET)
                followModule := sload(sub(followNFTSlot, 1))
                followNFT := sload(followNFTSlot)
            }

            if (followNFT == address(0)) {
                followNFT = _deployFollowNFT(profileId);
                assembly {
                    sstore(followNFTSlot, followNFT)
                }
            }

            tokenIds[i] = IFollowNFT(followNFT).mint(follower);

            if (followModule != address(0)) {
                IFollowModule(followModule).processFollow(
                    follower,
                    profileId,
                    followModuleDatas[i]
                );
            }
            unchecked {
                ++i;
            }
        }
        emit Events.Followed(follower, profileIds, followModuleDatas, block.timestamp);
        return tokenIds;
    }

    function collect(
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata collectModuleData,
        address collectNFTImpl,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
    ) internal returns (uint256) {
        (uint256 rootProfileId, uint256 rootPubId, address rootCollectModule) = Helpers
            .getPointedIfMirrorWithCollectModule(profileId, pubId);

        uint256 tokenId;
        // Avoids stack too deep
        {
            address collectNFT = _pubByIdByProfile[rootProfileId][rootPubId].collectNFT;
            if (collectNFT == address(0)) {
                collectNFT = _deployCollectNFT(
                    rootProfileId,
                    rootPubId,
                    _profileById[rootProfileId].handle,
                    collectNFTImpl
                );
                _pubByIdByProfile[rootProfileId][rootPubId].collectNFT = collectNFT;
            }
            tokenId = ICollectNFT(collectNFT).mint(collector);
        }

        ICollectModule(rootCollectModule).processCollect(
            profileId,
            collector,
            rootProfileId,
            rootPubId,
            collectModuleData
        );
        _emitCollectedEvent(
            collector,
            profileId,
            pubId,
            rootProfileId,
            rootPubId,
            collectModuleData
        );

        return tokenId;
    }

    /**
     * @notice Deploys the given profile's Follow NFT contract.
     *
     * @param profileId The token ID of the profile which Follow NFT should be deployed.
     *
     * @return address The address of the deployed Follow NFT contract.
     */
    function _deployFollowNFT(uint256 profileId) private returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IFollowNFT.initialize.selector,
            profileId
        );
        address followNFT = address(new FollowNFTProxy(functionData));
        emit Events.FollowNFTDeployed(profileId, followNFT, block.timestamp);

        return followNFT;
    }

    /**
     * @notice Deploys the given profile's Collect NFT contract.
     *
     * @param profileId The token ID of the profile which Collect NFT should be deployed.
     * @param pubId The publication ID of the publication being collected, which Collect NFT should be deployed.
     * @param handle The profile's associated handle.
     * @param collectNFTImpl The address of the Collect NFT implementation that should be used for the deployment.
     *
     * @return address The address of the deployed Collect NFT contract.
     */
    function _deployCollectNFT(
        uint256 profileId,
        uint256 pubId,
        string memory handle,
        address collectNFTImpl
    ) private returns (address) {
        address collectNFT = Clones.clone(collectNFTImpl);

        bytes4 firstBytes = bytes4(bytes(handle));

        string memory collectNFTName = string(
            abi.encodePacked(handle, COLLECT_NFT_NAME_INFIX, pubId.toString())
        );
        string memory collectNFTSymbol = string(
            abi.encodePacked(firstBytes, COLLECT_NFT_SYMBOL_INFIX, pubId.toString())
        );

        ICollectNFT(collectNFT).initialize(profileId, pubId, collectNFTName, collectNFTSymbol);
        emit Events.CollectNFTDeployed(profileId, pubId, collectNFT, block.timestamp);

        return collectNFT;
    }

    /**
     * @notice Emits the `Collected` event that signals that a successful collect action has occurred.
     *
     * @dev This is done through this function to prevent stack too deep compilation error.
     *
     * @param collector The address collecting the publication.
     * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
     * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
     * @param rootProfileId The profile token ID of the profile whose publication is being collected.
     * @param rootPubId The publication ID of the publication being collected.
     * @param data The data passed to the collect module.
     */
    function _emitCollectedEvent(
        address collector,
        uint256 profileId,
        uint256 pubId,
        uint256 rootProfileId,
        uint256 rootPubId,
        bytes calldata data
    ) private {
        emit Events.Collected(
            collector,
            profileId,
            pubId,
            rootProfileId,
            rootPubId,
            data,
            block.timestamp
        );
    }

    function _validateProfileExistsViaHandle(uint256 profileId) private view {
        bool shouldRevert;
        assembly {
            // Load the free memory pointer, where we'll return the value
            let ptr := mload(64)

            // Load the slot, which either contains the name + 2*length if length < 32 or
            // 2*length+1 if length >= 32, and the actual string starts at slot keccak256(slot)
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            let slot := add(keccak256(0, 64), PROFILE_HANDLE_OFFSET)

            let slotLoad := sload(slot)
            let size
            // Determine if the length > 32 by checking the lowest order bit, meaning the string
            // itself is stored at keccak256(slot)
            switch and(slotLoad, 1)
            case 0 {
                // The name is in the same slot
                // Determine the size by dividing the last byte's value by 2
                size := shr(1, and(slotLoad, 255))

                // Store the size in the first slot
                mstore(ptr, size)

                // Store the actual string in the second slot (without the size)
                mstore(add(ptr, 32), and(slotLoad, not(255)))
            }
            case 1 {
                // The handle is not in the same slot
                // Determine the size by dividing the value in the whole slot minus 1 by 2
                size := shr(1, sub(slotLoad, 1))

                // Store the size in the first slot
                mstore(ptr, size)

                // Compute the total memory slots we need, this is (size + 31) / 32
                let totalMemorySlots := shr(5, add(size, 31))

                mstore(0, slot)
                let handleSlot := keccak256(0, 32)

                // Iterate through the words in memory and store the string word by word
                // prettier-ignore
                for { let i := 0 } lt(i, totalMemorySlots) { i := add(i, 1) } {
                    mstore(add(add(ptr, 32), mul(32, i)), sload(add(handleSlot, i)))
                }
            }
            let handleHash := keccak256(add(ptr, 32), size)
            mstore(0, handleHash)
            mstore(32, PROFILE_ID_BY_HANDLE_HASH_MAPPING_SLOT)
            let handleHashSlot := keccak256(0, 64)
            let resolvedProfileId := sload(handleHashSlot)
            shouldRevert := iszero(eq(resolvedProfileId, profileId))
            // Store the new memory pointer in the free memory pointer slot
            mstore(64, add(add(ptr, 32), size))
        }
        if (shouldRevert) revert Errors.TokenDoesNotExist();
    }
}
