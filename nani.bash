#! /bin/bash


now_status () {
  UNTRACKED_NUM=`git status -s | grep "^??" | wc -l | sed 's/ //g'`
  CHANGED_NUM=`git status -s | grep -E "^ M|^MM" | wc -l | sed 's/ //g'`
  DELETED_NUM=`git status -s | grep "^ D" | wc -l | sed 's/ //g'`
  NEWSTAGED_NUM=`git status -s | grep "^A " | wc -l | sed 's/ //g'`
  MODSTAGED_NUM=`git status -s | grep -E "^M |^MM" | wc -l | sed 's/ //g'`
  DELSTAGED_NUM=`git status -s | grep "^D " | wc -l | sed 's/ //g'`
  echo "----- ローカル -----"
  echo "新[${UNTRACKED_NUM}] 変[${CHANGED_NUM}] 削[${DELETED_NUM}]"
  echo "----- ステージ -----"
  echo "新[${NEWSTAGED_NUM}] 変[${MODSTAGED_NUM}] 削[${DELSTAGED_NUM}]"
  echo "--------------------"
}

checkout () {
  echo "[1] git checkout ブランチ移動"
  echo "[2] git checkout -b ブランチ作成"
  read -n 1 -p "checkout? > " command
  echo
  case "${command}" in    #変数strの内容で分岐
    [1])
      branches=$(git branch -vv)
      branch=$(echo "${branches}" | fzf +m)
      if [ -z "${branch}" ]; then
        read -n 1 -p "キャンセルしました。" DAMMY
      else
          git checkout $(echo "${branch}" | awk '{print $1}' | sed "s/.* //")
          press_any_key
      fi
    ;;
    [2])
      echo "作成したいGit名を入力(何も入れないとキャンセル)"
      read -p ":" INPUT_STR
      # git branch ${INPUT_STR}
      if [ -z "${INPUT_STR}" ]; then
        read -n 1 -p "キャンセルしました。" DAMMY
      else
        git checkout -b ${INPUT_STR}
        read -n 1 -p "[${INPUT_STR}]ブランチを作成しました。" DAMMY
      fi
      ;;
  esac
}


gitlog () {
  echo "[1] git log ログをそのまま表示"
  echo "[2] git branch ブランチを一覧表示"
  echo "[3] *fshow 履歴をツリー表示する"
  echo "[4] *super_diff ファイルの履歴を深堀りする"

  read -n 1 -p "info? > " command
  echo
  case "${command}" in    #変数strの内容で分岐
    [1]) git log ;;
    [2]) git branch ;;
    [3]) fshow ;;
    [4]) super_diff ;;
  esac
}


commit () {
  read -n 1 -p "コミットします。Viが開くので、コメントメッセージを入れて保存してください。" DAMMY
  git commit
}
# commit_old () {
#   echo "[1] git commit -m １行でコミットを作成"
#   echo "[2] git commit Viを使ってコミットを作成"
#
#   read -n 1 -p "info? > " command
#   echo
#   case "${command}" in    #変数strの内容で分岐
#     [1])
#       echo "コミットメッセージを入れてください（何も入れないとキャンセルします）"
#       read -p ":" INPUT_STR
#       if [ -z "${INPUT_STR}" ]; then
#         IS_CANCEL=true
#         read -n 1 -p "キャンセルしました。" DAMMY
#       else
#         git commit -m '${INPUT_STR}'
#         read -n 1 -p "コミットしました" DAMMY
#       fi
#       ;;
#     [2])
#       read -n 1 -p "コミットします。Viが開くので、コメントメッセージを入れて保存してください。" DAMMY
#       git commit
#       ;;
#     *) echo "キャンセルしました";IS_CANCEL=true;;
#   esac
#
# }


press_any_key () {
  read -n 1 -p "なにかキーを押してください: " DAMMY
}

super_diff () {
  dir=`find . -type d -name '.git' -prune -o -type f -print | fzf`
  git log -p ${dir}
}
gitadd () {
  echo "[1] git add . すべてステージングエリアにあげる"
  echo "[2] git add -i 選択してステージングにあげる"

  read -n 1 -p "git add? > " command
  echo
  case "${command}" in    #変数strの内容で分岐
    [1]) git add . && echo "すべてステージングにあげました。" &&  press_any_key ;;
    [2]) git add -i ;;
    *) echo "キャンセルしました";IS_CANCEL=true;;
  esac

}
fshow () {
  git log --graph --color=always \
  --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
  --bind "ctrl-m:execute:
  (grep -o '[a-f0-9]\{7\}' | head -1 |
  xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
  {}q
  FZF-EOF"

}

add_commit_push () {
  echo "--------------------"
  echo "add -> commit -> pushウィザードです"
  now_status
  read -n 1 -p "addします。" DAMMY
  gitadd
  if [ "${IS_CANCEL}" = true ]; then return; fi
  now_status
  read -n 1 -p "commitします。" DAMMY
  commit
  if [ "${IS_CANCEL}" = true ]; then return; fi
  now_status
  read -n 1 -p "pushします。" DAMMY
  git push origin ${BRANCH_NAME} && read -n 1 -p "プッシュしました。" DAMMY
}

# Main
echo "なに？"
while true
do
  IS_CANCEL=false
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD | sed 's/ //g'`
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

  now_status
  echo "[0] git checkout ブランチ移動・作成"
  echo "[1] info ログ表示・調査"
  echo "[2] git status 作業ツリー内の差分ファイルを表示"
  echo "[3] git diff 何処を編集したのか確認"
  echo "[4] git add ステージングエリアにあげる"
  echo "[5] git commit コミットする"
  echo "[6] git push origin ${BRANCH_NAME} プッシュする"
  echo "[7] git pull origin ${BRANCH_NAME} プルする"
  echo "[8] add -> commit -> pushウィザード"
  echo "[q] exit"
  read -n 1 -p "コマンド? > " command
  echo
  case "${command}" in    #変数strの内容で分岐
    [0]) checkout;;
    [1]) gitlog ;;
    [2]) git status && press_any_key ;;
    [3]) git diff;;
    [4]) gitadd;;
    [5]) commit;;
    [6]) git push origin ${BRANCH_NAME} && read -n 1 -p "プッシュしました。" DAMMY;;
    [7]) git pull origin ${BRANCH_NAME} && read -n 1 -p "プルしました。" DAMMY;;
    [8]) add_commit_push;;
    [Qq]) echo "QUIT" && exit;;
    *)    echo "なに？";;
  esac
done
