//                 //
// Validator Types //
//                 //

// flatList of Assets
pub type SpendAction {
  assets: List<(ByteArray, ByteArray, Int)>,
}

// VerificationKeyHash'
pub type ConfigDatum {
  signatures: List<ByteArray>,
  threshold: Int,
}

// VerificationKeyHash'
pub type ConfigMintAction {
  CMint { signatures: List<ByteArray>, threshold: Int }
  CBurn
}

// VerificationKeyHash'
pub type ConfigAction {
  Add { sig: ByteArray }
  Remove { sig: ByteArray }
  Update { threshold: Int }
}
