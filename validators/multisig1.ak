use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, NoDatum, OutputReference, Transaction}
use multisig/types.{ConfigAction, ConfigDatum, SpendAction}
use multisig/utils

//                  //
// MultiSig Example //
//                  //

// This Multisig aims to solve the problem of Datum dependant signatories lists
// A dynamic validator needs to have a sigs and a threshold value to be able to 
// validate spending, but you also need to allow freedom of different Datums.

// to achieve this we will offload the multisig configuration settings into a
// reference_input so the validator can rely on it without having to know the 
// settings in advance.

// currently we will only have spending abilities, but in the future I might
// expand to other script purposes like staking and voting

validator multiSig(cp: PolicyId) {
  spend(
    datum: Option<Data>,
    r: SpendAction,
    oref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(ownIn) =
      list.find(tx.inputs, fn(in) { in.output_reference == oref })

    let ownHash = ownIn.output.address.payment_credential

    expect Some(configIn) =
      list.find(
        tx.reference_inputs,
        fn(in) { list.has(assets.policies(in.output.value), cp) },
      )

    expect InlineDatum(dat) = configIn.output.datum
    expect cDatum: ConfigDatum = dat

    let spendingAssets = utils.foldFlatValue(r.assets)
    when datum is {
      None -> {
        let ownIns =
          list.filter(
            tx.inputs,
            fn(in) { in.output.address.payment_credential == ownHash },
          )

        let ownOuts =
          list.filter(
            tx.outputs,
            fn(out) { out.address.payment_credential == ownHash },
          )

        // TODO: Make FlatAssetList Redeemer & check inValue == assets.merge(outValue, redeemerValue)
        let (inValue, outValue) = utils.sumInsOuts(ownIns, ownOuts)

        and {
          list.all(ownIns, fn(in) { in.output.datum == NoDatum }),
          list.count(
            cDatum.signatures,
            fn(sig) { list.has(tx.extra_signatories, sig) },
          ) >= cDatum.threshold,
        }
      }
      Some(d) -> {
        expect 1 =
          list.count(
            tx.inputs,
            fn(in) { in.output.address.payment_credential == ownHash },
          )

        if assets.merge(assets.negate(spendingAssets), ownIn.output.value) != assets.zero {
          let ownOuts =
            list.filter(
              tx.outputs,
              fn(out) { out.address.payment_credential == ownHash },
            )
          expect Some(ownOut) = list.head(ownOuts)
          and {
            list.length(ownOuts) == 1,
            ownIn.output.value == assets.merge(ownOut.value, spendingAssets),
            list.count(
              cDatum.signatures,
              fn(sig) { list.has(tx.extra_signatories, sig) },
            ) >= cDatum.threshold,
          }
        } else {
          list.count(
            cDatum.signatures,
            fn(sig) { list.has(tx.extra_signatories, sig) },
          ) >= cDatum.threshold
        }
      }
    }
    // has config input
    // has config datum
    // get multisig input(s)
    // get multisig output(s)

    // redeemer has value?
    // list of token quantities

    // sum of output values == sum of input values - redeemer value
  }

  else(_) {
    fail
  }
}
