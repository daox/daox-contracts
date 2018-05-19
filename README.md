# Daox Contracts &nbsp; [![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Daox%20is%20a%20solution%20that%20lets%20startups%20and%20investors%20form%20decentralized%20autonomous%20organizations%20on%20Ethereum%20blockchain&url=https://daox.org&hashtags=blockchain,ethereum,dapps,dao,investment) <img align="right" src="https://raw.githubusercontent.com/daox/daox-contracts/840ebd10400d1d81b6b324116f009d2154e07b07/assets/daox-logo_github%402x.png" height="34px" />

[![Build Status](https://travis-ci.org/daox/daox-contracts.svg?branch=master)](https://travis-ci.org/daox/daox-contracts)

This repo contains Solidity smart contracts to create decentralized autonomous organizations for [the Daox platform](https://platform.daox.org).

Install
-------

### Clone the repository:

```bash
git clone https://github.com/daox/daox-contracts.git
cd daox-contracts
```

### Install requirements with npm:

```bash
npm i
```

### Install truffle and ganache-cli for testing and compiling:

```bash
npm i -g truffle ganache-cli
```

Testing
-------------------
### Run all tests (will automatically run ganache-cli in the background):

```bash
npm test
```

Compile and Deploy
------------------
Compiled contracts are already stored in repository so in regular case you will not need to compile it. 
But if it is needed for some reason use instructions below

### Compile all contracts:

```bash
truffle compile
```

License
-------
All smart contracts are released under MIT.

Contributors
------------
- Anton Vityazev ([GiddeonWyeth](https://github.com/GiddeonWyeth))
- Kirill Bulgakov ([bulgakovk](https://github.com/bulgakovk))
- Alex Shevlyakov ([sanchosrancho](https://github.com/sanchosrancho))
