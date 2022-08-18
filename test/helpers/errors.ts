export const ERRORS = {
  CANNOT_INIT_IMPL: 'CannotInitImplementation()',
  INITIALIZED: 'Initialized()',
  SIGNATURE_EXPIRED: 'SignatureExpired()',
  ZERO_SPENDER: 'ZeroSpender()',
  SIGNATURE_INVALID: 'SignatureInvalid()',
  NOT_OWNER_OR_APPROVED: 'NotOwnerOrApproved()',
  NOT_HUB: 'NotHub()',
  TOKEN_DOES_NOT_EXIST: 'TokenDoesNotExist()',
  NOT_GOVERNANCE: 'NotGovernance()',
  NOT_GOVERNANCE_OR_EMERGENCY_ADMIN: 'NotGovernanceOrEmergencyAdmin()',
  EMERGENCY_ADMIN_CAN_ONLY_PAUSE_FURTHER: 'EmergencyAdminCanOnlyPauseFurther()',
  COLLECT_MODULE_NOT_WHITELISTED: 'CollectModuleNotWhitelisted()',
  FOLLOW_MODULE_NOT_WHITELISTED: 'FollowModuleNotWhitelisted()',
  REFERENCE_MODULE_NOT_WHITELISTED: 'ReferenceModuleNotWhitelisted()',
  PROFILE_CREATOR_NOT_WHITELISTED: 'ProfileCreatorNotWhitelisted()',
  NOT_PROFILE_OWNER: 'NotProfileOwner()',
  NOT_PROFILE_OWNER_OR_VALID: 'NotProfileOwnerOrValid()',
  PUBLICATION_DOES_NOT_EXIST: 'PublicationDoesNotExist()',
  PROFILE_HANDLE_TAKEN: 'HandleTaken()',
  INVALID_HANDLE_LENGTH: 'HandleLengthInvalid()',
  INVALID_IMAGE_URI_LENGTH: 'ProfileImageURILengthInvalid()',
  HANDLE_CONTAINS_INVALID_CHARACTERS: 'HandleContainsInvalidCharacters()',
  HANDLE_FIRST_CHARACTER_INVALID: 'HandleFirstCharInvalid()',
  NOT_FOLLOW_NFT: 'CallerNotFollowNFT()',
  NOT_COLLECT_NFT: 'CallerNotCollectNFT()',
  BLOCK_NUMBER_INVALID: 'BlockNumberInvalid()',
  INIT_PARAMS_INVALID: 'InitParamsInvalid()',
  COLLECT_EXPIRED: 'CollectExpired()',
  COLLECT_NOT_ALLOWED: 'CollectNotAllowed()',
  MINT_LIMIT_EXCEEDED: 'MintLimitExceeded()',
  FOLLOW_INVALID: 'FollowInvalid()',
  MODULE_DATA_MISMATCH: 'ModuleDataMismatch()',
  FOLLOW_NOT_APPROVED: 'FollowNotApproved()',
  ARRAY_MISMATCH: 'ArrayMismatch()',
  CANNOT_COMMENT_ON_SELF: 'CannotCommentOnSelf',
  NOT_DISPATCHER: 'NotDispatcher()',

  // ERC721Time + ERC721Enumerable errors
  ERC721_NOT_OWN: 'ERC721Time_TransferOfTokenThatIsNotOwn()',
  ERC721_TRANSFER_NOT_OWNER_OR_APPROVED: 'ERC721Time_TransferCallerNotOwnerOrApproved()',
  ERC721_OWNER_QUERY_FOR_NONEXISTENT_TOKEN: 'ERC721Time_OwnerQueryForNonexistantToken()',
  ERC20_TRANSFER_EXCEEDS_ALLOWANCE: 'ERC20: transfer amount exceeds allowance',
  ERC20_INSUFFICIENT_ALLOWANCE: 'ERC20: insufficient allowance',
  NO_SELECTOR:
    "Transaction reverted: function selector was not recognized and there's no fallback function",
  PAUSED: 'Paused()',
  PUBLISHING_PAUSED: 'PublishingPaused()',
  NO_REASON_ABI_DECODE:
    "Transaction reverted and Hardhat couldn't infer the reason. Please report this to help us improve Hardhat.",
};
