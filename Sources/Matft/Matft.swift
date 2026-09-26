//
//  Matft.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

/**
   The namespace of Matft, a Numpy-like multi-dimensional array library.

   `Matft` itself is never instantiated. It groups the array creation and manipulation
   functions (the counterpart of the top-level `numpy` module, e.g. `Matft.arange`,
   `Matft.expand_dims`) and the sub-namespaces below
   (`Matft.linalg`, `Matft.math`, `Matft.stats`, `Matft.random`, `Matft.fft`, ...).

   ```swift
   let a = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])
   let b = Matft.expand_dims(a, axis: 0)
   ```
*/
public class Matft{

    /**
       Linear algebra functions. Equivalent to `numpy.linalg`.
    */
    public class linalg{}
    
    /**
       Element-wise mathematical functions (trigonometric, exponential, rounding, ...), like Numpy's ufuncs.
    */
    public class math{}
    
    /**
       Statistics and reduction functions (mean, max, sum, ...).
    */
    public class stats{}
    
    /**
       Random number generation. Equivalent to `numpy.random`.
    */
    public class random{}
    
    /**
       Text file input/output (`loadtxt`, `genfromtxt`, `savetxt`), like the Numpy functions of the same names.
     */
    public class file{}
    
    /**
       One-dimensional interpolation. Equivalent to `scipy.interpolate.interp1d`.
     */
    public class interp1d{}
    
    /**
       Image processing functions (color conversion, resize, affine warp, ...), modeled after `cv2`.
     */
    public class image{}
    
    /**
       Discrete Fourier transforms. Equivalent to `numpy.fft`.
     */
    public class fft{}
    
    /**
       Functions for complex arrays (`angle`, `conjugate`, `abs`, `absarg`).
     */
    public class complex{}
    
    /**
       Audio signal processing (windows, framing, STFT, mel spectrogram, ...), modeled after `librosa`.
     */
    public class audio{}
    
    /**
       The kernel of mfarray.
    */
    //internal class mfdata{}
    
    /**
       Subscript marker that inserts a new axis of length 1. Equivalent to `numpy.newaxis`.
    */
    public static var newaxis: SubscriptOps{
        return .newaxis
    }
    
    /**
       Subscript marker that selects all elements along an axis (alias for `0~<`, i.e. `:` in Numpy).
    */
    public static var all: SubscriptOps{
        return .all
    }
    
    /**
       Subscript marker that selects all elements along an axis in reverse order (alias for `~<<-1`, i.e. `::-1` in Numpy).
    */
    public static var reverse: SubscriptOps{
        return .reverse
    }
}
