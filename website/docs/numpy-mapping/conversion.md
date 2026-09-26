---
title: Conversion and Search
---

# Conversion and Search

| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.astype` | `numpy.astype` | ✓ | ✓ |
| `Matft.transpose` | `numpy.transpose` | ✓ | ✓ |
| `Matft.expand_dims` | `numpy.expand_dims` | ✓ | ✓ |
| `Matft.squeeze` | `numpy.squeeze` | ✓ | ✓ |
| `Matft.broadcast_to` | `numpy.broadcast_to` | ✓ | ✓ |
| `Matft.to_contiguous` | `numpy.ascontiguousarray` | ✓ | ✓ |
| `Matft.flatten` | `numpy.flatten` | ✓ | ✓ |
| `Matft.flip` | `numpy.flip` | ✓ | ✓ |
| `Matft.clip` | `numpy.clip` | ✓ | ✓ |
| `Matft.swapaxes` | `numpy.swapaxes` | ✓ | ✓ |
| `Matft.moveaxis` | `numpy.moveaxis` | ✓ | ✓ |
| `Matft.roll` | `numpy.roll` | ✓ |  |
| `Matft.sort` | `numpy.sort` | ✓ |  |
| `Matft.argsort` | `numpy.argsort` | ✓ |  |
| `Matft.pad` | `numpy.pad` | ✓ |  |
| `Matft.diff` | `numpy.diff` | ✓ |  |
| `MfArray.toArray` | `numpy.ndarray.tolist` | only |  |
| `MfArray.toFlattenArray` | n/a | only |  |
| `MfArray.toMLMultiArray` | n/a | only |  |
| `Matft.orderedUnique` | `numpy.unique` | ✓ |  |
| `Matft.unique / unique_values` | `numpy.unique / numpy.unique_values` |  |  |
| `Matft.unique_counts / unique_inverse / unique_all` | `numpy.unique_counts / unique_inverse / unique_all` |  |  |
| `Matft.nonzero` | `numpy.nonzero` |  |  |
| `Matft.argwhere` | `numpy.argwhere` |  |  |
| `Matft.where` | `numpy.where` |  |  |
| `Matft.searchsorted` | `numpy.searchsorted` |  |  |
| `Matft.digitize` | `numpy.digitize` |  |  |
| `Matft.bincount` | `numpy.bincount` |  |  |
| `Matft.histogram` | `numpy.histogram` |  |  |
| `Matft.isin` | `numpy.isin` |  |  |
| `Matft.intersect1d / union1d / setdiff1d` | `numpy.intersect1d / union1d / setdiff1d` |  |  |
