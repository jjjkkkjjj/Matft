---
title: Operation
---

# Operation

The second line of each cell is the infix (prefix) operator.

## Operators

| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.add`<br />`+` | `numpy.add`<br />`+` |  | ✓ |
| `Matft.sub`<br />`-` | `numpy.subtract`<br />`-` |  | ✓ |
| `Matft.div`<br />`/` | `numpy.divide`<br />`/` |  | ✓ |
| `Matft.mul`<br />`*` | `numpy.multiply`<br />`*` |  | ✓ |
| `Matft.inner`<br />`*+` | `numpy.inner`<br />n/a |  |  |
| `Matft.cross`<br />`*^` | `numpy.cross`<br />n/a |  |  |
| `Matft.matmul`<br />`*&` | `numpy.matmul`<br />`@` |  |  |
| `Matft.dot` | `numpy.dot` |  |  |
| `Matft.equal`<br />`===` | `numpy.equal`<br />`==` |  |  |
| `Matft.not_equal`<br />`!==` | `numpy.not_equal`<br />`!=` |  |  |
| `Matft.less`<br />`<` | `numpy.less`<br />`<` |  |  |
| `Matft.less_equal`<br />`<=` | `numpy.less_equal`<br />`<=` |  |  |
| `Matft.greater`<br />`>` | `numpy.greater`<br />`>` |  |  |
| `Matft.greater_equal`<br />`>=` | `numpy.greater_equal`<br />`>=` |  |  |
| `Matft.allEqual`<br />`==` | `numpy.array_equal`<br />n/a |  | ✓ |
| `Matft.neg`<br />`-` | `numpy.negative`<br />`-` |  | ✓ |

## Universal function reduction

| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.ufuncReduce`<br />e.g. `Matft.ufuncReduce(mfarray: a, ufunc: Matft.add)` | `numpy.add.reduce`<br />e.g. `numpy.add.reduce(a)` | ✓ | ✓ |
| `Matft.ufuncAccumulate`<br />e.g. `Matft.ufuncAccumulate(mfarray: a, ufunc: Matft.add)` | `numpy.add.accumulate`<br />e.g. `numpy.add.accumulate(a)` | ✓ | ✓ |
