//                               //
// Config Validator For MultiSig //
//                               //

// This validator will manage the creation and updating of a config token
// which will hold all of the multisig members and min sig rules

pub type ConfigDatum {
  signatures: List<VerificationKeyHash>,
  threshold: Int,
}

pub type ConfigMintAction {
  CMint {
    signatures: List<VerificationKeyHash>,
    threshold: Int,
  }
  CBurn
}

pub type ConfigAction {
  Add { sig }
  Remove { sig }
  Update { threshold }
}

validator config(boot: OutputReference) {
  mint(r: ConfigMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(cName, cAmt)] =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()

    when r is {
      CMint { signatures, threshold } -> {
        expect Some(bootIn) =
          list.find(tx.inputs, fn(input) { input.output_reference == boot })

        expect Some(ownOut) =
          list.find(
            tx.outputs,
            fn(out) { output.address.payment_credential == Script(p) },
          )

        expect InlineDatum(datum) = ownOut.datum
        expect cDatum: ConfigDatum = datum

        and {
          list.has(assets.policies(ownOut.value), p),
          cName == "",
          cAmt == 1,
          cDatum.signatures == signatures,
          cDatum.threshold == threshold,
        }
      }
      CBurn -> and {
          cName == "",
          cAmt == -1,
        }
    }
    // mints config token with configDatum
  }

  spend(datum: Option<ConfigDatum>, r: ConfigAction, oref: OutputReference, tx: Transaction) {
    when datum is {
      None -> True
      Some(d) -> {
        expect Some(ownIn) = 
          list.find(
            tx.inputs,
            fn(in) { 
              in.output_reference == oref
            }
          )
        
        let ownHash = ownIn.output.address.payment_credential

        when r is {
          Add { signature } -> {
            expect Some(ownOut) = 
              list.find(
                tx.outputs,
                fn(out) {
                  output.address == ownIn.output.address
                }
              )
            
            expect InlineDatum(datum) = ownOut.datum
            expect cDatum: ConfigDatum = datum 

            and {
              d.threshold == cDatum.threshold,
              list.concat(d.signatures, [signature]),
              list.has(d.signatures, signature) == False,
              list.unique(cDatum.signatures) == cDatum.signatures,
              list.count(d.signatories, fn(sig) { tx.extra_signatories, sig }) >= d.threshold,
              assets.without_lovelace(ownIn.output.value) == assets.without_lovelace(ownOut.value)
            }
          }
          Remove { signature } -> {
            expect Some(ownOut) = 
              list.find(
                tx.outputs,
                fn(out) {
                  output.address == ownIn.output.address
                }
              )
            
            expect InlineDatum(datum) = ownOut.datum
            expect cDatum: ConfigDatum = datum 

            and {
              d.threshold == cDatum.threshold,
              list.delete(d.signatures, [signature]),
              list.has(cDatum.signatures, signature) == False,
              list.unique(cDatum.signatures) == cDatum.signatures,
              list.count(d.signatories, fn(sig) { tx.extra_signatories, sig }) >= d.threshold,
              assets.without_lovelace(ownIn.output.value) == assets.without_lovelace(ownOut.value)
            }
          }
          Update { threshold } -> {
            expect Some(ownOut) = 
              list.find(
                tx.outputs,
                fn(out) {
                  output.address == ownIn.output.address
                }
              )
            
            expect InlineDatum(datum) = ownOut.datum
            expect cDatum: ConfigDatum = datum 

            and {
              threshold == cDatum.threshold,
              d.signatures == cDatum.signatures,
              list.count(cDatum.signatories, fn(sig) { tx.extra_signatories, sig }) >= d.threshold,
              assets.without_lovelace(ownIn.output.value) == assets.without_lovelace(ownOut.value)
            }
          }
        }
      }
    }
    
    // manages multisig members and signing thresholds
  }

  else(_) {
    fail
  }
}
