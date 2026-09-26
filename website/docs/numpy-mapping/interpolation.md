---
title: Interpolation
---

# Interpolation

## Numpy

| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.interp` | `numpy.interp` |  |  |
| `Matft.polyfit` | `numpy.polyfit` |  |  |
| `Matft.polyval` | `numpy.polyval` |  |  |

## Scipy

`Matft.interp1d.cubicSpline` supports `natural`, `clamped`, `notAKnot` and `periodic` boundary conditions via `bc_type`.

| Matft | Scipy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.interp1d.cubicSpline` | `scipy.interpolate.CubicSpline` |  |  |
| `Matft.interp1d.linear` | `scipy.interpolate.interp1d(kind='linear')` |  |  |
| `Matft.interp1d.nearest` | `scipy.interpolate.interp1d(kind='nearest')` |  |  |
| `Matft.interp1d.previous` | `scipy.interpolate.interp1d(kind='previous')` |  |  |
| `Matft.interp1d.next` | `scipy.interpolate.interp1d(kind='next')` |  |  |
