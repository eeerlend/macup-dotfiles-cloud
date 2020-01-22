# macup-dotfiles-cloud

A [macup](https://github.com/eeerlend/macup-builder) module that keeps your dotfiles in sync through cloud drive

## Installation
Run the following command to add it to your repo

```bash
npm install eeerlend/macup-dotfiles-cloud --save
```

## Configuration
Add your dotfiles to your macup configuration file like this...

```bash
macup_dotfiles_cloud_files+=(
  myfile
  myotherfile:644
  .ssh/config:644
  .ssh/my_private_key:600
)
macup_dotfiles_cloud_type=icloud|dropbox
```

... following the `filename:chmod` pattern. All filenames should be relative to your HOME directory, `$HOME/`
