# 1. 概要
このリポジトリは、LLMを利用したツールのためにGoogle Cloud上のインフラストラクチャを Terraform を使用してプロビジョニングおよび管理するためのコードベースです。

## 2. プロジェクト構造

主要なTerraform設定ファイルとディレクトリは以下の通りです。

```
.
├── main.tf              # メインのリソース定義（GCSバケットなど）とプロバイダ設定
├── iam.tf               # IAM関連のリソース定義（サービスアカウント、IAMポリシー）
├── variables.tf         # プロジェクト共通の変数定義
├── outputs.tf           # Terraform実行後の出力値定義（オプション、必要に応じて）
├── .terraform.lock.hcl  # プロバイダの依存関係ロックファイル
└── .gitignore           # Git管理から除外するファイル
```

* `main.tf`: TerraformのGoogle Cloudプロバイダ設定と、Terraformの状態ファイル（tfstate）を保存するためのCloud Storageバケットを定義します。
* `iam.tf`: Terraformを実行するためのサービスアカウント、およびClaude CodeがVertex AIにアクセスするためのサービスアカウント、それらに付与されるIAMロールを定義します。
* `variables.tf`: プロジェクトID、リージョン、ゾーンなど、Terraform設定全体で使用する変数を定義します。
* `outputs.tf` (任意): Terraformによって作成されたリソースの情報を出力するために使用します（例: サービスアカウントのメールアドレスなど）。
* `.terraform.lock.hcl`: Terraformのプロバイダのバージョンをロックし、異なる環境での一貫した実行を保証します。**このファイルはGitにコミットします。**
* `.gitignore`: Gitリポジトリから除外すべきファイル（`.tfstate`、サービスアカウントキーファイル、`.terraform/` ディレクトリなど）を指定します。

## 3. IAM (Identity and Access Management) 戦略

このプロジェクトでは、最小権限の原則に基づき、以下の専用サービスアカウントを定義しています。

* **`terraform-runner@<project-id>.iam.gserviceaccount.com`**:
    * **役割**: このTerraformコードを実行するために使用されるサービスアカウントです。
    * **権限**:
        * `roles/storage.objectAdmin`: Terraformの状態ファイル (`.tfstate`) を保存するCloud Storageバケット内のオブジェクトに対する読み書き権限。
        * `roles/iam.serviceAccountCreator`: このプロジェクト内で新しいサービスアカウントを作成する権限。
        * `roles/aiplatform.admin`: Vertex AI関連のリソース（モデル、エンドポイントなど）を管理する権限。**注意: 必要に応じてより具体的なロールに絞り込んでください。**

* **`claude-code-user@<project-id>.iam.gserviceaccount.com`**:
    * **役割**: Vertex AI上でAnthropic Claudeモデルを呼び出すコード（Claude Code）が使用するサービスアカウントです。
    * **権限**:
        * `roles/aiplatform.user`: Vertex AIのモデルに対して推論リクエストを送信する権限。
        * `roles/logging.logWriter`: Vertex AIの利用ログをCloud Loggingに書き込む権限。

## 4. 前提条件

* Google Cloud Platform (GCP) プロジェクトが作成済みであること。
* `gcloud` CLI がインストールされ、プロジェクトに認証済みであること。
* Terraform CLI がインストール済みであること。
* **Terraformを実行する主体（ユーザーまたはCI/CDサービスアカウント）が、このTerraformコードによって作成される`terraform-runner`サービスアカウントになりすます権限 (`roles/iam.serviceAccountTokenCreator`) を持っていること。**
    * 例: Cloud Build を使用する場合、Cloud Build のサービスアカウント（`[PROJECT_NUMBER]@cloudbuild.gserviceaccount.com`）に、`terraform-runner` サービスアカウントに対する `roles/iam.serviceAccountTokenCreator` を付与する必要があります。

    ```bash
    # 例: Cloud Build サービスアカウントに権限を付与する場合
    # まず、Terraform Runner Service Account のメールアドレスを確認
    # TERRAFORM_RUNNER_SA="terraform-runner@your-gcp-project-id.iam.gserviceaccount.com"

    # gcloud iam service-accounts add-iam-policy-binding ${TERRAFORM_RUNNER_SA} \
    #     --member="serviceAccount:${CLOUD_BUILD_SA}" \
    #     --role="roles/iam.serviceAccountTokenCreator"
    ```

## 5. Terraformの実行方法

### 5.1. 変数ファイルの準備

`variables.tf` で定義されている変数に値を渡すために、`terraform.tfvars` ファイルを作成します（Gitにはコミットしません）。

```hcl
# terraform.tfvars (このファイルはGitにコミットしないでください)
project = "your-gcp-project-id"
# region = "asia-northeast1" # デフォルト値を使用しない場合は指定
# zone   = "asia-northeast1-a" # デフォルト値を使用しない場合は指定
```

### 5.2. 初期化

Terraformの設定を初期化し、プロバイダのダウンロードとバックエンド（GCS）の設定を行います。

```bash
terraform init -backend-config="bucket=${project-id}-tfstate"
```

### 5.3. 実行計画の確認

Terraformが実際にどのような変更を行うかを確認します。

```bash
terraform plan
```

### 5.4. 適用

計画された変更をGCPに適用し、リソースを作成します。

```bash
terraform apply
```

確認プロンプトが表示されたら `yes` と入力してEnterキーを押します。

### 5.5. リソースの破棄 (注意: 本番環境では慎重に)

作成したすべてのTerraform管理下のGCPリソースを破棄します。**このコマンドは非常に強力なので、本番環境では絶対に実行しないでください。**

```bash
terraform destroy
```

## 6. クリーンアップ

Terraform管理外で作成されたリソースや、ローカルのTerraformキャッシュを削除する場合。

```bash
rm -rf .terraform/ .terraform.lock.hcl terraform.tfstate*
```

## 7. 開発者向け情報

* **認証**: Terraformを実行する際は、`gcloud auth application-default set-service-account` コマンドで `terraform-runner` サービスアカウントになりすまして実行することを推奨します。
    ```bash
    gcloud auth application-default set-service-account terraform-runner@your-gcp-project-id.iam.gserviceaccount.com
    ```
* **`.gitignore`**: 以下のファイルをGitリポジトリから除外するよう設定しています。
    ```
    # .gitignore
    .terraform/
    *.tfstate
    *.tfstate.*
    *.tfvars # 機密情報を含むtfvarsファイルは除外
    # secrets.tfvars (もしあれば)
    ```
