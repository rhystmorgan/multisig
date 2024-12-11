use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use multisig/types.{ConfigDatum, SpendAction}
use multisig1 as m
use tests/tools as t

test multiSig1() {
  // multisig configuration
  let config = #"aaaa"
  let memberList = [#"0000", #"1111", #"2222", #"3333", #"4444"]
  let threshold = 3

  // ref input
  let configDatum = ConfigDatum(memberList, threshold)
  let configValue = t.makeAsset(config, "", 1)

  let configIn =
    t.input(
      t.oref(#"bbbb", 2),
      t.output(t.scriptAddress(config), configValue, InlineDatum(configDatum)),
    )

  // Spending Input
  let oref = t.oref(#"cccc", 3)
  let in =
    t.input(oref, t.output(t.scriptAddress(#"dddd"), t.makeAda(100), NoDatum))

  let out = t.output(t.scriptAddress(#"dddd"), t.makeAda(50), NoDatum)

  let spentOut = t.output(t.walletAddress(#"eeee"), t.makeAda(50), NoDatum)

  let spendAction = SpendAction(assets.flatten(t.makeAda(50)))

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      inputs: [in],
      outputs: [out, spentOut],
      extra_signatories: [#"0000", #"3333", #"4444"],
    }

  m.multiSig.spend(config, None, spendAction, oref, tx)
}

test multiSig3() {
  // multisig configuration
  let config = #"aaaa"
  let memberList = [#"0000", #"1111", #"2222", #"3333", #"4444"]
  let threshold = 3

  // ref input
  let configDatum = ConfigDatum(memberList, threshold)
  let configValue = t.makeAsset(config, "", 1)

  let configIn =
    t.input(
      t.oref(#"bbbb", 2),
      t.output(t.scriptAddress(config), configValue, InlineDatum(configDatum)),
    )

  // Spending Input
  let oref = t.oref(#"cccc", 3)
  let in1 =
    t.input(oref, t.output(t.scriptAddress(#"dddd"), t.makeAda(50), NoDatum))

  let in2 =
    t.input(
      t.oref(#"dddd", 2),
      t.output(t.scriptAddress(#"dddd"), t.makeAda(30), NoDatum),
    )

  let in3 =
    t.input(
      t.oref(#"eeee", 3),
      t.output(t.scriptAddress(#"dddd"), t.makeAda(20), NoDatum),
    )

  let out = t.output(t.scriptAddress(#"dddd"), t.makeAda(50), NoDatum)

  let spentOut = t.output(t.walletAddress(#"eeee"), t.makeAda(50), NoDatum)

  let spendAction = SpendAction(assets.flatten(t.makeAda(50)))

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      inputs: [in1, in2, in3],
      outputs: [out, spentOut],
      extra_signatories: [#"0000", #"3333", #"4444"],
    }

  and {
    m.multiSig.spend(config, None, spendAction, oref, tx),
    m.multiSig.spend(config, None, spendAction, t.oref(#"dddd", 2), tx),
    m.multiSig.spend(config, None, spendAction, t.oref(#"eeee", 3), tx),
  }
}
