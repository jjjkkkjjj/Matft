import UIKit
import Matft
import Accelerate

/*
    Initialization
*/
do{
    let a = MfArray([[[ -8,  -7,  -6,  -5],
                      [ -4,  -3,  -2,  -1]],
            
                     [[ 0,  1,  2,  3],
                      [ 4,  5,  6,  7]]])
    print(a)
}
do{
    let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
    print(a)
}
do{
    let a = Matft.nums(Float(1), shape: [2,2,4])
    print(a)
}

/*
    Conversion
*/
do{// type
    let a = Matft.arange(start: -6, to: 21, by: 1, shape: [3,3,3], mftype: .Int)
    print(a)
    print(a.astype(.UInt8))
    print(a.astype(.Float))
}

do{// indexing
    let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
    print(a[~<1])
    print(a[1~<3])
    print(a[~<~<2])
    print(a[Matft.all, 0])
    print(a[~<-1])
    print(a[-1~<-3])
    
    a[~<1] = Matft.arange(start: 0, to: 81, by: 9, shape: [3, 3])
    print(a)
}
do{// boolean indexing
    let img = Matft.arange(start: -5, to: 70, by: 1, shape: [5, 5, 3], mftype: .Float)
    print(img)
    print(img[img < 0])
    
    img[img < 0] = MfArray([0])
    print(img)
}

do{
    let a = MfArray([[1, 2], [3, 4], [5, 6]])
                
    a[MfArray([0, 1, 2]), MfArray([0, -1, 0])] = MfArray([999,888,777])
    print(a)
     
    a.T[MfArray([0, 1, -1]), MfArray([0, 1, 0])] = MfArray([-999,-888,-777])
    print(a)
}

do{
    let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
                
    let b = a[0~<, 1]
    b[~<<-1] = MfArray([9999]) // cannot pass Int directly such like 9999

    print(a)
}

/*
    Math
*/

do{// arithmetic
    let a = Matft.arange(start: 0, to: 3*3, by: 1, shape: [3,3])

    print(a+a)
    print(a-a)
    print(a*a)
    print(a/a)
}

do{// broadcasting
    let a = Matft.arange(start: 0, to: 3*3, by: 1, shape: [3,3])
    let b = MfArray([-4, 10, 2]).reshape([3, 1])
    print(a+b)
}
