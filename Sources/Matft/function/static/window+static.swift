//
//  window+static.swift
//  Matft
//

import Foundation

extension Matft{
    /**
       Return the (symmetric) Hanning window. Same as `np.hanning`
       - parameters:
            - M: Number of points in the output window
       - Returns: The window (Double)
    */
    public static func hanning(_ M: Int) -> MfArray{
        return _cosine_window(M, coefs: [0.5, 0.5])
    }

    /**
       Return the (symmetric) Hamming window. Same as `np.hamming`
       - parameters:
            - M: Number of points in the output window
       - Returns: The window (Double)
    */
    public static func hamming(_ M: Int) -> MfArray{
        return _cosine_window(M, coefs: [0.54, 0.46])
    }

    /**
       Return the (symmetric) Blackman window. Same as `np.blackman`
       - parameters:
            - M: Number of points in the output window
       - Returns: The window (Double)
    */
    public static func blackman(_ M: Int) -> MfArray{
        return _cosine_window(M, coefs: [0.42, 0.5, 0.08])
    }

    /**
       Return the (symmetric) Bartlett window. Same as `np.bartlett`
       - parameters:
            - M: Number of points in the output window
       - Returns: The window (Double)
    */
    public static func bartlett(_ M: Int) -> MfArray{
        return _window(M){
            n in
            let half = Double(M - 1) / 2
            return 1 - abs(Double(n) - half) / half
        }
    }

    /**
       Return the Kaiser window. Same as `np.kaiser`
       - parameters:
            - M: Number of points in the output window
            - beta: Shape parameter for window
       - Returns: The window (Double)
    */
    public static func kaiser(_ M: Int, beta: Double) -> MfArray{
        return _window(M){
            n in
            let alpha = Double(M - 1) / 2
            let r = (Double(n) - alpha) / alpha
            return _bessel_i0(beta * (1 - r*r).squareRoot()) / _bessel_i0(beta)
        }
    }
}

/// Create the symmetric window of M points. M == 1 returns [1] as numpy
internal func _window(_ M: Int, _ value: (Int) -> Double) -> MfArray{
    if M < 1{
        return MfArray([] as [Double], mftype: .Double, shape: [0])
    }
    if M == 1{
        return MfArray([1.0], mftype: .Double)
    }
    return MfArray((0..<M).map(value), mftype: .Double)
}

/// Generalized cosine window: sum_k (-1)^k * coefs[k] * cos(2*pi*k*n/(M-1))
fileprivate func _cosine_window(_ M: Int, coefs: [Double]) -> MfArray{
    return _window(M){
        n in
        let x = 2 * Double.pi * Double(n) / Double(M - 1)
        var ret = 0.0
        for (k, c) in coefs.enumerated(){
            ret += (k % 2 == 0 ? c : -c) * cos(Double(k) * x)
        }
        return ret
    }
}

/// Modified Bessel function of the first kind, order 0 (power series)
fileprivate func _bessel_i0(_ x: Double) -> Double{
    let y = x * x / 4
    var term = 1.0
    var sum = 1.0
    var k = 1.0
    while term > sum * 1e-17{
        term *= y / (k * k)
        sum += term
        k += 1
    }
    return sum
}
