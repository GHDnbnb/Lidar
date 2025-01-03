# 项目名称 - PD_ACC

## 简介
可见光红外加速器rtl代码以及各模块功能描述文档

---

## 分支命名规范

为了保持项目分支管理的整洁和一致性，请按照以下规则命名分支.  
#### 注意,以下分支命名前需加上自己姓名和创建分支日期的缩写，例如`ghd0103/fix/critical-bug`

1. **主分支**
   - `main`：主分支，始终保持稳定，仅包含经过测试的代码，禁止未经沟通擅自覆盖远程`main`分支。
   
2. **功能分支**
   - 格式：`feature/<功能描述>`
   - 示例：`feature/add-login`、`feature/update-dashboard`
   - 用途：开发新的功能。

3. **修复分支**
   - 格式：`fix/<修复描述>`
   - 示例：`fix/login-bug`、`fix/api-error`
   - 用途：修复项目中的 Bug。

4. **发布分支**
   - 格式：`release/<版本号>`
   - 示例：`release/v1.0.0`
   - 用途：为发布新版本做准备，完成测试和最终优化，在本项目中可用作阶段性bug或者功能开发完毕后对于上游main分支覆盖前的备份。

5. **紧急修复分支**
   - 格式：`hotfix/<修复描述>`
   - 示例：`hotfix/critical-bug`
   - 用途：解决紧急问题。

---

## 代码上传操作流程

1. **确保切换到开发分支**
   ```bash
   git checkout <your-name-data/function/describe>
   ```
2. **检查当前状态 查看本地更改**
   ```bash
   git status
   ```
3. **添加更改到暂存区**
   ```bash
   git add <file>  # 添加特定文件
   git add .       # 添加所有更改
   ```
- **注意**，修改rtl代码后同样要按照日期以及名字的格式在对应代码或代码段后添加注释，例如：
   ```verilog
    self.ctrl_base_addr = ctrl_base_addr //ghd0105
   ```

4. **提交更改 提交更改并添加提交说明**

    ```bash
    git commit -m "简要描述更改内容"
    ```
- **注意**，在每次发布更改时需要在各自项目原本readme的基础上加上版本修改说明以及对应的日期，例如：
  - 0105：修改了xxx，解决了xxx问题  
  - 0106：在xxx文件加入了xxx注释  
   ...

5. **推送到远程分支 将本地更改同步到远程仓库**
    ```bash
    git push origin <your-name-data/function/describe>
    ```

## 代码下载操作流程

1. **拉取远程分支代码 确保获取远程分支的最新代码**

   ```bash
   git fetch origin
   ```

2. **切换到目标分支 切换到需要的分支**

   ```bash
   git checkout <your-name-data/function/describe>
   ```

3. **合并远程分支（如果需要） 将远程分支的最新代码合并到本地**

   ```bash
   git pull
   ```

## 注意事项
1. 保持分支整洁

   - 每个分支只处理一个功能或一个问题，完成任务后及时合并到主分支，并删除无用分支。

2. 提交信息清晰

   - 提交信息应简洁明了，描述本次提交的主要内容。  
   - 示例：
    
   ```plaintext  
   Add user login feature
   Fix bug in authentication API
   ```

3. 避免在 main 分支直接开发

    - 所有开发工作应在功能分支或修复分支上完成。

4. 处理冲突

    - 在合并分支时如果遇到冲突，先解决冲突再提交。
    - 解决冲突步骤：
    
    ```bash
    # 编辑冲突文件，删除冲突标记
    git add <file>
    git commit -m "Resolve merge conflicts"
    ```
5. 同步代码

    - 在开发新功能前，确保本地分支与远程分支同步：
  
    ```bash
    git pull origin <your-name-data/function/describe>
    ```

## 例子
### 创建并切换到新分支
```bash
git checkout -b feature/add-login
```

### 提交更改并推送到远程分支
```bash
git add .
git commit -m "Add user login functionality"
git push origin feature/add-login
```

### 拉取远程代码并合并
```bash
git pull origin main
```

## 常用命令汇总


| 功能                     | 命令示例                               |
|--------------------------|----------------------------------------|
| 查看当前分支              | `git branch`                          |
| 创建新分支并切换到该分支  | `git checkout -b <your-name-data/function/describe>`        |
| 切换到其他分支            | `git checkout <your-name-data/function/describe>`           |
| 添加文件到暂存区          | `git add <file>` 或 `git add .`        |
| 提交更改                 | `git commit -m "commit message"`      |
| 推送分支到远程            | `git push origin <your-name-data/function/describe>`        |
| 拉取远程代码              | `git pull origin <your-name-data/function/describe>`        |
| 查看状态                 | `git status`                          |
| 查看提交历史              | `git log`                             |
