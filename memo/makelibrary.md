# 備忘録

## ライブラリの作成

- [ここ](https://qiita.com/am10/items/72dbc511efc512fc065a)を参考に，File >New > Swift Packageで作成

- 特にできたファイルはいじらなくてよかった

- Sourceディレクトリにコードを書く
  
## SwiftPM対応

  - 開発者
    - バージョンができたら，commitにタグをつけ，pushする

      ```bash
      git tag -a x.x.x -m "メッセージ" (commit id)"
      ```

      ※**x.x.x**の形でないといけない
      ※ブランチだとたぶんうまくいかない

      ```bash
      git push --tags
      ```

    - タグの削除

      ```bash
      git tag --delete {tagname}
      git push origin :{tag name}/
      ```

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
  
- dynamic frameworkの用意
  →〜.xcodeprojの作成

  ```bash
  swift package generate-xcodeproj
  ```

- File > New Target > iOS > framework
  作成
  →Manage Scheme

- SchemeをShareする

  Product > Scheme > Manage Schemes
  ![scheme](https://user-images.githubusercontent.com/16914891/77147395-7496c080-6ad0-11ea-84d9-5c9ee8cab01a.png)
  
- ビルド（ライブラリ直下で）

  ```/bin/bash
  carthage build --no-skip-current
  ```

- 問題なくできていたら，gitでタグ付けすればOK

  

## CocoaPods

- 開発者

  - podspecファイル作成

    ```bash
    pod spec create Matft
    ```

  - 編集

    ※`spec.version`は随時更新する必要ありそう

    ```bash
    Pod::Spec.new do |spec|
      spec.name           = "Matft"
      spec.version        = "0.1.1"
      spec.summary        = "Numpy-like matrix operation library in swift"
      spec.homepage       = "https://github.com/jjjkkkjjj/Matft"
      spec.license        = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
      spec.author         = "jjjkkkjjj"
      spec.platform       = :ios, "10.0"
      spec.swift_versions = "4.0"
      spec.pod_target_xcconfig  = { 'SWIFT_VERSION' => '4.0' }
      spec.source         = { :git => "https://github.com/jjjkkkjjj/Matft.git", :tag => "#{spec.version}" }
      spec.source_files   = "Sources/**/*"
    end
    ```

  - 確認

    ```bash
    pod lib lint
    ```

  - 登録（初回のみ）

    ```bash
    pod trunk register ~@mail 'name'
    ```

    →メールが届くので，認証する

  - 更新

    ※--allow-warningsはもし，``pod lib lint``でwarningが出て，無視して良い時．
    
    ```bash
  pod trunk push Matft.podspec #--allow-warnings
    ```

    ※ミスった場合は一回消す
    
    ```bash
    pod trunk delete Matft x.x.x(version number)
    pod cache clean --all
    ```

- 使用者

  - Podfileファイル作成

    ```bash
    pod init
    ```

  - 以下追記

    ```bash
    target 'project' do
      pod 'Matft'
    end
    ```

  - インストール

    ```bash
    pod install
    ```

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
  
- Carthage
  https://qiita.com/mokumoku/items/340e089f34a284c0532a