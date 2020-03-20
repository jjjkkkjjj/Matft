# 備忘録

## ライブラリの作成

- [ここ](https://qiita.com/am10/items/72dbc511efc512fc065a)を参考に，File >New > Swift Packageで作成

- 特にできたファイルはいじらなくてよかった

- Sourceディレクトリにコードを書く
  
## SwiftPM対応

  - 開発者
    - バージョンができたら，commitにタグをつけ，pushする
      - git tag -a **x.x.x** -m "メッセージ" (commit id)"
        ※**x.x.x**の形でないといけない
        ※ブランチだとたぶんうまくいかない
      - git push --tags
  
  - 使用者
  
    - Project > Build Setting > + でgitのURL入れて，適宜選ぶ
      ![Build Setting](https://user-images.githubusercontent.com/16914891/77144994-b0c72280-6aca-11ea-8633-1fb1a13ec74d.png)
    
      ![select](https://user-images.githubusercontent.com/16914891/77144995-b1f84f80-6aca-11ea-8f4d-911bd96013cb.png)
    
    - アップデート
      ![update](https://user-images.githubusercontent.com/16914891/77145225-4367c180-6acb-11ea-98ea-8d7a5a2a669f.png)
    

## Carthage対応

- Carthageインストール
  ```bin/bash
  brew update
  brew install carthage
  ```
  
- SchemeをShareする

  Product > Scheme > Manage Schemes
  ![scheme](https://user-images.githubusercontent.com/16914891/77147395-7496c080-6ad0-11ea-84d9-5c9ee8cab01a.png)
  
- ビルド（ライブラリ直下で）

  ```/bin/bash
  carthage build --no-skip-current
  ```

- 問題なくできていたら，gitでタグ付けすればOK

  

## README.md

- バッジの作成
  https://shields.io/#/



## 参考

- swift OSS全般
  https://qiita.com/shtnkgm/items/0f62398c66af159401a6
  https://qiita.com/morizotter/items/2e45f8f94c1010ebd69f

- Swift PM
  https://qiita.com/am10/items/72dbc511efc512fc065a

  https://qiita.com/hironytic/items/09a4c16857b409c17d2c