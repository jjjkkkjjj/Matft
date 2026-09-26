//
//  interpolation.swift
//  
//
//  Created by AM19A0 on 2020/12/15.
//

import Foundation

extension Matft{
    /**
        One-dimensional linear interpolation like numpy.interp. Returned mfarray's type is float and its shape is same as x.
       - parameters:
            - x: mfarray. The x-coordinates at which to evaluate the interpolated values.
            - xp: mfarray. The x-coordinates of the data points. Must be 1d and increasing.
            - fp: mfarray. The y-coordinates of the data points. Must be 1d and same size as xp.
            - left: (Optional) Float. Value to return for x < xp[0]. Default is fp[0].
            - right: (Optional) Float. Value to return for x > xp[-1]. Default is fp[-1].
    */
    public static func interp(_ x: MfArray, xp: MfArray, fp: MfArray, left: Float? = nil, right: Float? = nil) -> MfArray{
        unsupport_complex(x)
        unsupport_complex(xp)
        unsupport_complex(fp)
        precondition(xp.ndim == 1 && fp.ndim == 1, "xp and fp must be 1d")
        precondition(xp.size == fp.size && xp.size >= 1, "xp and fp must be same size and not empty")
        
        let xs = xp.astype(.Float).toArray() as! [Float]
        let ys = fp.astype(.Float).toArray() as! [Float]
        let left = left ?? ys.first!, right = right ?? ys.last!
        let newx = x.astype(.Float).flatten().toArray() as! [Float]
        
        let newy = newx.map{ x -> Float in
            if x < xs.first!{
                return left
            }
            else if x > xs.last!{
                return right
            }
            else if xs.count == 1{
                return ys[0]
            }
            return _linear_interp(xs, ys, _interval_index(xs, x), x)
        }
        
        return MfArray(newy, shape: x.shape)
    }
}

extension Matft.interp1d{
    /**
        Return CubicSpline instance. The instance can interpolate by 'interpolate' method.
       - parameters:
            - x: mfarray
            - y: mfarray
            - axis: Int. Default is -1.
            - assume_sorted: Bool
            - bc_type: Boundary condition type. natural, clamped, notAKnot and periodic are supported. Default is natural. Note that scipy's default is not-a-knot.
    */
    public static func cubicSpline(x: MfArray, y: MfArray, axis: Int = -1, assume_sorted: Bool = true, bc_type: CubicSpline.BoundaryCondition = .natural) -> CubicSpline{
        unsupport_complex(x)
        unsupport_complex(y)
        
        let input = _preprocessing_interp(x, y, axis, assume_sorted)
        var spline = CubicSpline(orig_x: input.orig_x, orig_y: input.orig_y, axis: input.axis, assume_sorted: assume_sorted, bc_type: bc_type)
        return spline.fit()
    }
}

extension Matft.interp1d{
    /**
        Return Interp1d instance for linear interpolation. The instance can interpolate by 'interpolate' method.
       - parameters:
            - x: mfarray
            - y: mfarray
            - axis: Int. Default is -1.
            - assume_sorted: Bool
    */
    public static func linear(x: MfArray, y: MfArray, axis: Int = -1, assume_sorted: Bool = true) -> Interp1d{
        return _interp1d(x, y, axis, assume_sorted, .linear)
    }
    
    /**
        Return Interp1d instance for nearest interpolation. Note that the midpoint of the interval returns the left point's value. The instance can interpolate by 'interpolate' method.
       - parameters:
            - x: mfarray
            - y: mfarray
            - axis: Int. Default is -1.
            - assume_sorted: Bool
    */
    public static func nearest(x: MfArray, y: MfArray, axis: Int = -1, assume_sorted: Bool = true) -> Interp1d{
        return _interp1d(x, y, axis, assume_sorted, .nearest)
    }
    
    /**
        Return Interp1d instance for previous interpolation, which returns the previous point's value. The instance can interpolate by 'interpolate' method.
       - parameters:
            - x: mfarray
            - y: mfarray
            - axis: Int. Default is -1.
            - assume_sorted: Bool
    */
    public static func previous(x: MfArray, y: MfArray, axis: Int = -1, assume_sorted: Bool = true) -> Interp1d{
        return _interp1d(x, y, axis, assume_sorted, .previous)
    }
    
    /**
        Return Interp1d instance for next interpolation, which returns the next point's value. The instance can interpolate by 'interpolate' method.
       - parameters:
            - x: mfarray
            - y: mfarray
            - axis: Int. Default is -1.
            - assume_sorted: Bool
    */
    public static func next(x: MfArray, y: MfArray, axis: Int = -1, assume_sorted: Bool = true) -> Interp1d{
        return _interp1d(x, y, axis, assume_sorted, .next)
    }
    
    fileprivate static func _interp1d(_ x: MfArray, _ y: MfArray, _ axis: Int, _ assume_sorted: Bool, _ kind: Interp1d.Kind) -> Interp1d{
        unsupport_complex(x)
        unsupport_complex(y)
        
        let input = _preprocessing_interp(x, y, axis, assume_sorted)
        var interp = Interp1d(orig_x: input.orig_x, orig_y: input.orig_y, axis: input.axis, assume_sorted: assume_sorted, kind: kind)
        return interp.fit()
    }
}

public struct Interp1d: MfInterpProtocol{
    typealias ParamsType = Interp1dParams
    public var params: Interp1dParams?
    
    internal var orig_x: MfArray
    internal var orig_y: MfArray
    internal var axis: Int
    internal var assume_sorted: Bool
    internal var kind: Kind
    
    public struct Interp1dParams: MfInterpParamsProtocol{
        let x: [Float]
        let y: [Float]
    }
    
    public enum Kind: Int{
        case linear
        case nearest
        case previous
        case next
    }
    
    internal mutating func fit() -> Interp1d {
        precondition(self.orig_x.size >= 2, "x must have at least 2 points")
        self.params = Interp1dParams(x: self.orig_x.toArray() as! [Float], y: self.orig_y.toArray() as! [Float])
        return self
    }
    
    public func interpolate(_ newx: MfArray) -> MfArray {
        precondition(newx.ndim == 1, "new x must be 1d")
        let newx = newx.astype(.Float).toArray() as! [Float]
        let xs = self.params!.x, ys = self.params!.y
        
        let newy = zip(newx, _interval_indices(xs, newx)).map{ (x, i) -> Float in
            switch self.kind {
            case .linear:
                return _linear_interp(xs, ys, i, x)
            case .nearest:
                return x - xs[i] <= xs[i+1] - x ? ys[i] : ys[i+1]
            case .previous:
                return x < xs[i+1] ? ys[i] : ys[i+1]
            case .next:
                return x > xs[i] ? ys[i+1] : ys[i]
            }
        }
        
        return MfArray(newy)
    }
}

public struct CubicSpline: MfInterpProtocol{
    typealias ParamsType = CubicSplineParams
    public var params: CubicSplineParams?
    
    internal var orig_x: MfArray
    internal var orig_y: MfArray
    internal var axis: Int
    internal var assume_sorted: Bool
    internal var bc_type: BoundaryCondition
    
    public struct CubicSplineParams: MfInterpParamsProtocol{
        let a: [Float]
        let b: [Float]
        let c: [Float]
        let d: [Float]
        
        public init(a: [Float], b: [Float], c: [Float], d: [Float]){
            assert((a.count == b.count) && (b.count == c.count) && (c.count == d.count), "All input mfarray must be same size")
            self.a = a
            self.b = b
            self.c = c
            self.d = d
        }
    }
    
    public enum BoundaryCondition: Int{
        /// The second derivative at both ends is zero
        case natural
        /// The first derivative at both ends is zero
        case clamped
        /// The third derivative is continuous at the second and second-to-last points
        case notAKnot
        /// The interpolated function is periodic with period x.last - x.first. y.first must be equal to y.last
        case periodic
    }
    
    internal mutating func fit() -> CubicSpline {
        /*
         Ref: http://www.yamamo10.jp/yamamoto/lecture/2006/5E/interpolation/interpolation.pdf
         // input
         (x_0, y_0),...,(x_N, y_N), size=(N+1,N+1)
         
         // piece-wise polynominal
         S_j(x) = a_j(x-x_j)^3 + b_j(x-x_j)^2 + c_j(x-x_j) + d_j, size=N
         j = 0,1,...,N-1
         
         // Definition for simplifying
         h_j = x_{j+1} - x_j, size=N
         j = 0,1,...,N-1
         
         v_j = 6{(y_{j+1}-y_j)/h_j - (y_j-y_{j-1})/h_{j-1}}, size=N-1
         j = 1,...,N-1
         
         // solve simultaneous equation for u_j = S''_j(x_j) (second derivative), size=N+1
         // j = 1,...,N-1 (inner rows)
         h_{j-1}u_{j-1} + 2(h_{j-1}+h_j)u_j + h_ju_{j+1} = v_j
         // j = 0, N (boundary rows) depend on bc_type
         natural: u_0 = 0, u_N = 0
         clamped: S'(x_0) = 0, S'(x_N) = 0
           2h_0u_0 + h_0u_1 = 6(y_1-y_0)/h_0
           h_{N-1}u_{N-1} + 2h_{N-1}u_N = -6(y_N-y_{N-1})/h_{N-1}
         notAKnot: S'''(x) is continuous at x_1 and x_{N-1}
           h_1u_0 - (h_0+h_1)u_1 + h_0u_2 = 0
           h_{N-1}u_{N-2} - (h_{N-2}+h_{N-1})u_{N-1} + h_{N-2}u_N = 0
           (*)Note that 3 points are a parabola (u_0 = u_1 = u_2), 2 points are a line (u_0 = u_1 = 0)
         periodic: S''(x_0) = S''(x_N), S'(x_0) = S'(x_N)
           u_0 - u_N = 0
           2h_0u_0 + h_0u_1 + h_{N-1}u_{N-1} + 2h_{N-1}u_N = 6{(y_1-y_0)/h_0 - (y_N-y_{N-1})/h_{N-1}}

         // piece-wise polynominal's coefs
         b_j = u_j/2, size=N
         a_j = (u_{j+1} - u_j)/6h_j, size=N
         c_j = (y_{j+1} - y_j)/h_j + h_j(2u_j + u_{j+1})/6
         d_j = y_j
         j = 0,1,...,N-1
         */
        // shape=(N+1,)
        let N = self.orig_x.size - 1
        precondition(N >= 1, "x must have at least 2 points")
        let xs = self.orig_x.toArray() as! [Float]
        let ys = self.orig_y.toArray() as! [Float]
        // shape=(N,)
        let h = self.orig_x[1~<] - self.orig_x[~<-1]
        let hs = (0..<N).map{ xs[$0+1] - xs[$0] }
        // slope of each interval, shape=(N,)
        let slope = (0..<N).map{ (ys[$0+1] - ys[$0])/hs[$0] }
        
        // coef * u = rhs, shape=(N+1,N+1) and (N+1,)
        var coef = Array(repeating: Array(repeating: Float.zero, count: N+1), count: N+1)
        var rhs = Array(repeating: Float.zero, count: N+1)
        for j in 1..<N{
            coef[j][j-1] = hs[j-1]
            coef[j][j] = 2*(hs[j-1] + hs[j])
            coef[j][j+1] = hs[j]
            rhs[j] = 6*(slope[j] - slope[j-1])
        }
        
        switch self.bc_type {
        case .natural:
            coef[0][0] = 1
            coef[N][N] = 1
        case .clamped:
            coef[0][0] = 2*hs[0]
            coef[0][1] = hs[0]
            rhs[0] = 6*slope[0]
            coef[N][N-1] = hs[N-1]
            coef[N][N] = 2*hs[N-1]
            rhs[N] = -6*slope[N-1]
        case .notAKnot where N == 1:
            coef[0][0] = 1
            coef[N][N] = 1
        case .notAKnot where N == 2:
            coef[0][0] = 1
            coef[0][1] = -1
            coef[N][N-1] = -1
            coef[N][N] = 1
        case .notAKnot:
            coef[0][0] = hs[1]
            coef[0][1] = -(hs[0] + hs[1])
            coef[0][2] = hs[0]
            coef[N][N-2] = hs[N-1]
            coef[N][N-1] = -(hs[N-2] + hs[N-1])
            coef[N][N] = hs[N-2]
        case .periodic:
            precondition(ys.first! == ys.last!, "The first and last y must be same for periodic boundary condition")
            coef[0][0] = 1
            coef[0][N] = -1
            // Note that += is needed because 0 == N-1 when N == 1
            coef[N][0] += 2*hs[0]
            coef[N][1] += hs[0]
            coef[N][N-1] += hs[N-1]
            coef[N][N] += 2*hs[N-1]
            rhs[N] = 6*(slope[0] - slope[N-1])
        }
        
        // shape=(N+1,)
        let u: MfArray
        do{
            u = try Matft.linalg.solve(MfArray(coef, mftype: .Float), b: MfArray(rhs, mftype: .Float))
        } catch {
            preconditionFailure("Invalid input x and y. Cannot calculate piecewise polynominals' coefficient")
        }
        
        // all params shape=(N,)
        let a = (u[1~<] - u[~<-1])/(6*h)
        let b = u[~<-1]/2

        let c = (self.orig_y[1~<] - self.orig_y[~<-1])/h - 1/Float(6)*h*(2*u[~<-1] + u[1~<])
        let d = self.orig_y[~<-1]
        self.params = CubicSplineParams(a: a.toArray() as! [Float], b: b.toArray() as! [Float], c: c.toArray() as! [Float], d: d.toArray() as! [Float])
        
        return self
    }
    
    internal func piecewise_func(index: Int, x: Float, orig_x: [Float]) -> Float{
        let a = self.params!.a[index]
        let b = self.params!.b[index]
        let c = self.params!.c[index]
        let d = self.params!.d[index]
        let x_xj = x - orig_x[index]

        return a*powf(x_xj, 3)+b*powf(x_xj, 2)+c*x_xj+d
    }

    public func interpolate(_ newx: MfArray) -> MfArray {
        precondition(newx.ndim == 1, "new x must be 1d")
        let newx = newx.astype(.Float).toArray() as! [Float]
        let orig_x = self.orig_x.toArray() as! [Float]

        let newy = zip(newx, _interval_indices(orig_x, newx)).map{
            self.piecewise_func(index: $1, x: $0, orig_x: orig_x)
        }

        return MfArray(newy)
    }
}
/*
public struct Lagrange: MfInterpProtocol{

}
*/

/// Return the index i of the interval [orig_x[i], orig_x[i+1]] which contains x.
/// Note that orig_x must be sorted and x == orig_x.last belongs to the last interval.
fileprivate func _interval_index(_ orig_x: [Float], _ x: Float) -> Int{
    // binary search for the largest i such that orig_x[i] <= x, i in [0, count-2]
    var lo = 0, hi = orig_x.count - 2
    while lo < hi{
        let mid = (lo + hi + 1) / 2
        if orig_x[mid] <= x{
            lo = mid
        }
        else{
            hi = mid - 1
        }
    }
    return lo
}

/// Return the interval indices for all new x. All new x must be within [orig_x.first, orig_x.last]
fileprivate func _interval_indices(_ orig_x: [Float], _ newx: [Float]) -> [Int]{
    let first = orig_x.first!, last = orig_x.last!
    return newx.map{ x in
        precondition(first <= x && x <= last, "input value \(x) must be within [\(first), \(last)]")
        return _interval_index(orig_x, x)
    }
}

/// Linear interpolation in the interval [orig_x[i], orig_x[i+1]]
fileprivate func _linear_interp(_ orig_x: [Float], _ orig_y: [Float], _ i: Int, _ x: Float) -> Float{
    return orig_y[i] + (orig_y[i+1] - orig_y[i])*(x - orig_x[i])/(orig_x[i+1] - orig_x[i])
}

fileprivate func _preprocessing_interp(_ orig_x: MfArray, _ orig_y: MfArray, _ axis: Int, _ assume_sorted: Bool) -> (orig_x: MfArray, orig_y: MfArray, axis: Int){
    precondition(orig_x.ndim == 1, "x must be 1d")
    precondition(orig_y.ndim > 0, "y must be more than 1d")
    let axis = get_positive_axis(axis, ndim: orig_y.ndim)
    precondition(orig_y.shape[axis] == orig_x.size, "The length of y along the interpolation axis must be equal to the length of x.")
    
    let x: MfArray, y: MfArray
    if !assume_sorted{
        let inds = orig_x.argsort()
        x = orig_x[inds].astype(.Float)
        y = Matft.take(orig_y, indices: inds).astype(.Float)
    }
    else{
        x = orig_x.astype(.Float)
        y = orig_y.astype(.Float)
    }
    
    return (x, y, axis)
}
