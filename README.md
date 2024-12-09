# Multisig Wallet In Aiken

This repo aims to solve the challenges of having a multisig in a Aiken.

Most multiSigs on Cardano use Native scripts because it will allow freedom of spending,
however there are some pitfalls of this approach. The main issue is updateability.

with Native scripts you cannot update the parameters of your multisig without ending up
with a new scipt and thus a new multisig.

This was still the most common practice because writing multisig validators in plutus
meant you had other problems to contend with, such as haveing `NoDatum`.

Now with PlutusV3 it is possible to handle `NoDatum`, but there is also another problem 
with most ( as far as I have seen ) Plutus multisig solutions.

This issue is the single UTxO thread.

Most open-source multisigs have a single `Authority Token` which holds the parameters of
the multisig in the datum, and all of the assets need to be in that UTxO to be spendable.

That, or you need to mint a new `Authority Token` every time you add a new UTxO to the 
address.

Each of these potential solutions has its own problem.

Multi Auth - This solution can easily result in different spending parameters because
  each datum can accidentally have a different list of signatories OR threshold.

Single UTxo - This can easily end up being unspendable by adding a few Native Assets.

The solution I have is to manage the multisig `Authority Token` separately to the address
and providing it as a reference input for spending.

This solves both of the above problems and more, because it allows for a single source of
parameters for signatories and threshold, whilst also allowing multiple UTxOs with various
different assets.

It also has another bonus in that it allows for non validator specific datums, so it will
be able to interact with dapps and store datums at UTxOs used for other purposes.

Enabling these different features means we can use multisigs on Cardano without the above
limitations, allowing multisigs to interact with other protocols and also enabling 
membership/threshold management and an unlimited amount of UTxOs with complete freedom in
how those UTxOs are spent.

> NOTE: There is actually a limitation ...
> In order for us to use arbitrary datums, we need to limit the number of UTxOs that can
> be spent if we are spending a UTxO with a datum, which is 1.

---

Write validators in the `validators` folder, and supporting functions in the `lib` folder using `.ak` as a file extension.

```aiken
validator my_first_validator {
  spend(_datum: Option<Data>, _redeemer: Data, _output_reference: Data, _context: Data) {
    True
  }
}
```

## Building

```sh
aiken build
```

## Configuring

**aiken.toml**
```toml
[config.default]
network_id = 41
```

Or, alternatively, write conditional environment modules under `env`.

## Testing

You can write tests in any module using the `test` keyword. For example:

```aiken
use config

test foo() {
  config.network_id + 1 == 42
}
```

To run all tests, simply do:

```sh
aiken check
```

To run only tests matching the string `foo`, do:

```sh
aiken check -m foo
```

## Documentation

If you're writing a library, you might want to generate an HTML documentation for it.

Use:

```sh
aiken docs
```

## Resources

Find more on the [Aiken's user manual](https://aiken-lang.org).
