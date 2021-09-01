#! /bin/bash
echo "なに？"
while true
do
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD | sed 's/ //g'`
  UNTRACKED_NUM=`git status -s | grep "^??" | wc -l | sed 's/ //g'`
  CHANGED_NUM=`git status -s | grep "^ M" | wc -l | sed 's/ //g'`
  DELETED_NUM=`git status -s | grep "^ D" | wc -l | sed 's/ //g'`
  NEWSTAGED_NUM=`git status -s | grep "^A " | wc -l | sed 's/ //g'`
  MODSTAGED_NUM=`git status -s | grep "^M " | wc -l | sed 's/ //g'`
  DELSTAGED_NUM=`git status -s | grep "^D " | wc -l | sed 's/ //g'`
  P_BRANCH_NAME="origin/${BRANCH_NAME}"
  BRANCHES=`git branch -a`
  echo "現在のブランチ:[${BRANCH_NAME}]"
  echo "親ブランチ:[${P_BRANCH_NAME}]"
  if [[ ${BRANCHES} =~ ${P_BRANCH_NAME}  ]] ;
  then
      # echo "マッチしたものがあります"
      LOG_COUNT_LO=`git log ${P_BRANCH_NAME}..${BRANCH_NAME} | wc -l | sed 's/ //g'`
      if [ ${LOG_COUNT_LO} = "0" ]; then
        LOG_COUNT_RE=`git log ${BRANCH_NAME}..${P_BRANCH_NAME} | wc -l | sed 's/ //g'`
        if [ ${LOG_COUNT_RE} = "0" ]; then
          echo "ブランチは最新です"
        else
          echo "プルされていないブランチがあります"
        fi
      else
        echo "プッシュされていないブランチがあります"
      fi
  else
    echo "親ブランチは存在しません"
  fi

  echo "----- ローカル -----"
  echo "新[${UNTRACKED_NUM}] 変[${CHANGED_NUM}] 削[${DELETED_NUM}]"
  echo "----- ステージ -----"
  echo "新[${NEWSTAGED_NUM}] 変[${MODSTAGED_NUM}] 削[${DELSTAGED_NUM}]"
  echo "--------------------"
  echo "[0] git checkout チェックアウト"
  echo "[1] git log Gitのログを表示"
  echo "[2] git status 作業ツリー内の差分ファイルを表示"
  echo "[3] git branch[list] ブランチを一覧表示"
  echo "[4] git checkout -b ブランチを新規作成してブランチに移動"
  echo "[5] git diff 何処を編集したのか確認"
  echo "[6] git add . すべてステージングエリアにあげる"
  echo "[7] git add -i 選択してステージングにあげる"
  echo "[8] git commit コミットする"
  echo "[9] git push origin ${BRANCH_NAME} プッシュする"
  echo "[s] *fshow 履歴をツリー表示する"
  echo "[d] *superdiff ファイルの履歴を深堀りする"
  echo "[q] exit"
  read -n 1 -p "コマンド? > " str  #標準入力（キーボード）から1文字け取って変数strにセット
  echo
  case "$str" in    #変数strの内容で分岐
    [0])
      branches=$(git branch -vv)
      branch=$(echo "${branches}" | fzf +m)
      if [ -z "${branch}" ]; then
        read -p "キャンセルしました。" DAMMY
      else
          git checkout $(echo "${branch}" | awk '{print $1}' | sed "s/.* //")
          read -p "なにかキーを押してください: " DAMMY

      fi
      ;;
    [1])
      git log
      ;;
    [2])
      git status
      read -p "なにかキーを押してください: " DAMMY
      ;;
    [3])
      # git branch -a
      git branch
      ;;
    [4])
      echo "作成したいGit名を入力"
      read -p ":" INPUT_STR
      # git branch ${INPUT_STR}
      if [ -z "${INPUT_STR}" ]; then
        read -p "キャンセルしました。" DAMMY
      else
        git checkout -b ${INPUT_STR}
        read -p "[${INPUT_STR}]ブランチを作成しました。" DAMMY
      fi
      ;;
    [5])
      git diff
      ;;
    [6])
      git add .
      echo "すべてステージングにあげました。"
      read -p "なにかキーを押してください: " DAMMY
      ;;
    [7])
      git add -i
      ;;
    [8])
      read -p "コミットします。Viが開くので、コメントメッセージを入れて保存してください。" DAMMY
      git commit
      ;;
    [9])
      git push origin ${BRANCH_NAME}
      read -p "プッシュしました。" DAMMY
      ;;
    [Qq])
      echo "QUIT"
      exit
      ;;
    [Dd])
      dir=`find . -type d -name '.git' -prune -o -type f -print | fzf`
      git log -p ${dir}
      ;;
    [Ss])
      git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
      (grep -o '[a-f0-9]\{7\}' | head -1 |
      xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
      {}
      FZF-EOF"
      ;;

    *)
      echo "なに？";;
  esac
done
