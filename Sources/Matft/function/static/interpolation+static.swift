//
//  interpolation.swift
//  
//
//  Created by AM19A0 on 2020/12/15.
//

import Foundation

extension Matft.interp1d{
    /**
        Return CubicSpline instance. The instance can interpolate by 'interpolate' method.
       - parameters:
            - x: mfarray
            - y: mfarray
            - axis: Int. Default is -1.
            - assume_sorted: Bool
            - bc_type: Boundary condition type. Natural is supported only.
    */
    public static func cubicSpline(x: MfArray, y: MfArray, axis: Int = -1, assume_sorted: Bool = true, bc_type: CubicSpline.BoundaryCondition = .natural) -> CubicSpline{
        unsupport_complex(x)
        unsupport_complex(y)
        
        let input = _preprocessing_interp(x, y, axis, assume_sorted)
        var spline = CubicSpline(orig_x: input.orig_x, orig_y: input.orig_y, axis: input.axis, assume_sorted: assume_sorted, bc_type: bc_type)
        return spline.fit()
    }
}

/*
public struct SLinearSpline: MfInterpProtocol{
    public var orig_x: MfArray
    
    public var orig_y: MfArray
    
    public func fit() -> SLinearSpline {
        <#code#>
    }
    
    public func interpolate(_ x: MfArray) -> MfArray {
        <#code#>
    }
    
    
    
}

public struct QuadraticSpline: MfInterpProtocol{
    
    
}*/

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
        case natural
        
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
         
         // solve simultaneous equation
         coef=
         (2(h_0+h_1) h_1                                     )
         (h_1        2(h_1+h_2) h_2               O          )
         ...
         (                          h_{N-2} 2(h_{N-2}+h_{N-1})
         , shape=(N-1,N-1)
         v_j, size=N-1
         j = 1,...,N-1
         
         // The above equations' root
         S''_j(x_j) = u_j (second derivative), size=N+1(*)
         j=1,...,N-1
         (*)Note that u_0 = u_N = 0 as hypothesis
         (*)u_N is defined for convenience
         
         // piece-wise polynominal's coefs
         b_j = u_j/2, size=N
         a_j = (u_{j+1} - u_j)/6h_j, size=N
         c_j = (y_{j+1} - y_j)/h_j + h_j(2u_j + u_{j+1})/6
         d_j = y_j
         j = 0,1,...,N-1
         */
        // shape=(N+1,)
        let N = self.orig_x.size - 1
        // shape=(N,)
        let h = self.orig_x[1~<] - self.orig_x[~<-1]
        // shape=(N-1,)
        let v = 6*((self.orig_y[2~<] - self.orig_y[1~<-1])/h[1~<] - (self.orig_y[1~<-1] - self.orig_y[~<-2])/h[~<-1])
        // shape=(N-1,N-1)
        let coef = Matft.diag(v: h[1~<-1], k: 1) + Matft.diag(v: 2*(h[~<-1] + h[1~<])) + Matft.diag(v: h[1~<-1], k: -1)
        // shape=(N+1,)
        let u = Matft.nums(Float.zero, shape: [N+1])
        do{
            u[1~<-1] = try Matft.linalg.solve(coef, b: v)
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
    
    internal func piecewise_index(startInd: Int, x: Float) -> Int{
        var ind = startInd
        
        let orig_x = self.orig_x.toArray() as! [Float]
        if ind == 0{
            // check if x is shorter than first value
            precondition(x >= orig_x.first!, "input value \(x) must be within [\(orig_x.first!), \(orig_x.last!)]")
            ind += 1
        }
        
        // Note that ind > 0
        while ind < self.orig_num {
            if orig_x[ind-1] <= x && x < orig_x[ind]{
                return ind - 1
            }
            
            ind += 1
        }
        if x == orig_x.last!{
            return orig_x.count - 2 // Note that piecewise polynominal function number is N-1
        }
        preconditionFailure("input value \(x) must be within [\(orig_x.first!), \(orig_x.last!)]")
    }
    
    public func interpolate(_ newx: MfArray) -> MfArray {
        precondition(newx.ndim == 1, "new x must be 1d")
        let _newx = newx.mftype == .Float ? newx : newx.astype(.Float)
        let sortedInds = _newx.argsort().data as! [Int]

        var newy = Array(repeating: Float.zero, count: _newx.size)
        
        let newx = _newx.toArray() as! [Float]
        
        var piecewise_ind = 0 // piecewise polynominal's index
        for (yi, xi) in sortedInds.enumerated(){
            
            piecewise_ind = self.piecewise_index(startInd: piecewise_ind, x: newx[xi])
            
            newy[yi] = self.piecewise_func(index: piecewise_ind, x: newx[xi], orig_x: self.orig_x.toArray() as! [Float])
        }
        
        return MfArray(newy)
    }
}
/*
public struct Lagrange: MfInterpProtocol{

}
*/

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
