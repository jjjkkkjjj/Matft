//
//  Matft.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public class Matft{

    /**
       Leanear algebra
    */
    public class linalg{}
    
    /**
       Basic math function
    */
    public class math{}
    
    /**
       MfArray Infomation
    */
    public class stats{}
    
    /**
       MfArray Infomation
    */
    public class random{}
    
    /**
       File Manager
     */
    public class file{}
    
    /**
       Interpolation
     */
    public class interp1d{}
    
    /**
       Image
     */
    public class image{}
    
    /**
       The kernel of mfarray.
    */
    //internal class mfdata{}
    
    /**
       Using in subscript, expand dimension
    */
    public static var newaxis: SubscriptOps{
        return .newaxis
    }
    
    /**
       Using in subscript, get all values (alias for `0~<`)
    */
    public static var all: SubscriptOps{
        return .all
    }
    
    /**
       Using in subscript, get all reversed values (alias for `0~<<-1`)
    */
    public static var reverse: SubscriptOps{
        return .reverse
    }
}
