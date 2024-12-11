use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use multisig/types.{
  Add, CBurn, CMint, ConfigAction, ConfigDatum, ConfigMintAction, Remove, Update,
}

//                               //
// Config Validator For MultiSig //
//                               //

// This validator will manage the creation and updating of a config token
// which will hold all of the multisig members and min sig rules

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
            fn(out) { out.address.payment_credential == Script(p) },
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

  spend(
    datum: Option<ConfigDatum>,
    r: ConfigAction,
    oref: OutputReference,
    tx: Transaction,
  ) {
    when datum is {
      None -> True
      Some(d) -> {
        expect Some(ownIn) =
          list.find(tx.inputs, fn(in) { in.output_reference == oref })
        let ownHash = ownIn.output.address.payment_credential

        when r is {
          Add { sig } -> {
            expect Some(ownOut) =
              list.find(
                tx.outputs,
                fn(out) { out.address == ownIn.output.address },
              )
            expect InlineDatum(datum) = ownOut.datum
            expect cDatum: ConfigDatum = datum

            and {
              d.threshold == cDatum.threshold,
              list.concat(d.signatures, [sig]) == cDatum.signatures,
              list.has(d.signatures, sig) == False,
              list.unique(cDatum.signatures) == cDatum.signatures,
              list.count(
                d.signatures,
                fn(sig) { list.has(tx.extra_signatories, sig) },
              ) >= d.threshold,
              assets.without_lovelace(ownIn.output.value) == assets.without_lovelace(
                ownOut.value,
              ),
            }
          }
          Remove { sig } -> {
            expect Some(ownOut) =
              list.find(
                tx.outputs,
                fn(out) { out.address == ownIn.output.address },
              )
            expect InlineDatum(datum) = ownOut.datum
            expect cDatum: ConfigDatum = datum

            and {
              d.threshold == cDatum.threshold,
              list.delete(d.signatures, sig) == cDatum.signatures,
              list.has(cDatum.signatures, sig) == False,
              list.unique(cDatum.signatures) == cDatum.signatures,
              list.count(
                d.signatures,
                fn(sig) { list.has(tx.extra_signatories, sig) },
              ) >= d.threshold,
              assets.without_lovelace(ownIn.output.value) == assets.without_lovelace(
                ownOut.value,
              ),
            }
          }
          Update { threshold } -> {
            expect Some(ownOut) =
              list.find(
                tx.outputs,
                fn(out) { out.address == ownIn.output.address },
              )
            expect InlineDatum(datum) = ownOut.datum
            expect cDatum: ConfigDatum = datum

            and {
              threshold == cDatum.threshold,
              d.signatures == cDatum.signatures,
              list.count(
                cDatum.signatures,
                fn(sig) { list.has(tx.extra_signatories, sig) },
              ) >= d.threshold,
              assets.without_lovelace(ownIn.output.value) == assets.without_lovelace(
                ownOut.value,
              ),
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
