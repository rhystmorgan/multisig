pub fn sumInsOuts(ins: List<Inputs>, outs: List<Outs>) -> (Value, Value) {
  let inValue =
    list.foldl(
      ins,
      assets.zero,
      fn(in, acc) { assets.merge(acc, in.output.value) },
    )

  let outValue =
    list.foldl(outs, assets.zero, fn(out, acc) { assets.merge(out.value, acc) })

  (inValue, outValue)
}

pub fn foldFlatValue(assets: List<(ByteArray, ByteArray, Int)>) -> Value {
  let value =
    list.foldl(
      r.assets,
      assets.zero,
      fn(asset, acc) {
        let (p, a, i) = asset
        assets.merge(acc, assets.from_asset(p, n, i))
      },
    )
  value
}
