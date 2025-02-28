use cardano/address.{Address, Script, VerificationKey}
use cardano/assets.{Value}
use cardano/transaction.{Datum, Input, Output, OutputReference}

pub fn makeAda(i: Int) {
  let value = assets.from_lovelace(i)
  value
}

pub fn makeAsset(p: ByteArray, n: ByteArray, q: Int) -> Value {
  let value = assets.from_asset(p, n, q)
  value
}

pub fn input(oref: OutputReference, output: Output) -> Input {
  let input = Input { output_reference: oref, output }
  input
}

pub fn oref(id: ByteArray, index: Int) -> OutputReference {
  let oref = OutputReference { transaction_id: id, output_index: index }
  oref
}

pub fn output(addr: Address, value: Value, datum: Datum) -> Output {
  let output = Output { address: addr, value, datum, reference_script: None }
  output
}

pub fn scriptAddress(s: ByteArray) -> Address {
  let address =
    Address { payment_credential: Script(s), stake_credential: None }

  address
}

pub fn walletAddress(p: ByteArray) -> Address {
  let address =
    Address { payment_credential: VerificationKey(p), stake_credential: None }
  address
}
