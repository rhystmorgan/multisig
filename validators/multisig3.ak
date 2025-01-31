// use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{
  InlineDatum, Input, NoDatum, OutputReference, Transaction,
}
use multisig/types.{ConfigDatum, SpendAction}

// use multisig/utils

//                  //
// MultiSig Example //
//                  //

// What if we remove all limitations except Datum protection?

validator multiWig(cp: PolicyId) {
  spend(_datum: Option<Data>, _r: Data, oref: OutputReference, tx: Transaction) {
    expect Some(ownInput) =
      list.find(tx.inputs, fn(input) { input.output_reference == oref })
    let ownHash = ownInput.output.address.payment_credential

    list.has(tx.withdrawals, Pair(ownHash, 0))
  }

  withdraw(_r: SpendAction, c: Credential, tx: Transaction) {
    expect Some(configIn) =
      list.find(
        tx.reference_inputs,
        fn(in) { list.has(assets.policies(in.output.value), cp) },
      )

    expect InlineDatum(dat) = configIn.output.datum
    expect cDatum: ConfigDatum = dat

    let ownIns =
      list.filter(
        tx.inputs,
        fn(in) { in.output.address.payment_credential == c },
      )

    expect Some(ownIn) = list.head(ownIns)

    when ownIn.output.datum is {
      NoDatum -> and {
          list.all(ownIns, fn(in) { in.output.datum == NoDatum }),
          list.count(
            cDatum.signatures,
            fn(sig) { list.has(tx.extra_signatories, sig) },
          ) >= cDatum.threshold,
        }
      _ -> {
        expect 1 = list.length(ownIns)

        list.count(
          cDatum.signatures,
          fn(sig) { list.has(tx.extra_signatories, sig) },
        ) >= cDatum.threshold
      }
    }
  }

  else(_) {
    fail
  }
}
