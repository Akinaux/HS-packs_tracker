#!/bin/bash
#set -vx

# Functions

fct_usage() {
  echo "Usage: $(basename $0) -a convert -s <sourcefile>     [-j <jsondata>] [-F <folder>]"
  echo "Usage: $(basename $0) -a extract [-l <logfile>]      [-j <jsondata>] [-F <folder>] [-W]"
  echo "Usage: $(basename $0) -a display [-f <html>|<ascii>] [-j <jsondata>] [-F <folder>] [-e <extension> [-p|-P]] [-t <number>] [-L <LANG>]"
  echo "	-a: Action you want to do: [ extract | convert | display ]"
  echo "	-e: Extension you want to display stats about [Default: Last_extension]"
  echo "	-f: Format to display the result [Default: ascii]"
  echo "	-F: Folder to store the data [Default: current folder]"
  echo "	-j: Json Data used by the script [Default: ${Script_name}.json]"
  echo "	-l: Log file where to extract the data from [Default: /Applications/Hearthstone/Logs/Achievements.log]"
  echo "	-L: Lang you want the cards to be displayed in"
  echo "	-p: Display the Pity Timers in addition of the cards for an extension (it requires [-e extension])"
  echo "	-P: Display ONLY the Pity Timers for an extension (it requires [-e extension])"
  echo "	-s: Source file from hspacktracker to convert"
  echo "	-t: Tail the database to display only <number> packs"
  echo "	-W: Wait for packs from the logfile to extract (use Ctrl+C to break the script)"
  echo "	-d: Run the script in debug mode (debug, info) [Suggested: info]"
  exit 1
}

ProgressBar() {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%% (${1}/${2})"
}

fct_inject_json() {
  EXT_release=11/03/2014
  for card in $Pack_cards
  do
    Set=$(echo $card | cut -d'_' -f1)
    PackSet+=($Set)
    Id=$(echo $card | cut -d':' -f1)
    Type=$(echo $card | cut -d':' -f2)
    Cards="$Cards,{\"id\":\"$Id\",\"type\":\"$Type\"}"
  done
  Cards=$(echo "[$Cards]" | sed -e "s/,//")
  sorted_unique_ids=($(echo "${PackSet[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  Set=""
  case "${sorted_unique_ids[@]}" in
    "CS1 CS2 EX1 NEW1 tt"|"CS1 CS2 EX1 NEW1"|"CS1 CS2 EX1 tt"|"CS1 CS2 NEW1 tt"|"CS1 EX1 NEW1 tt"|"CS1 CS2 tt"|"CS1 CS2 NEW1"|"CS1 CS2 EX1"|"CS1 EX1 tt"|"CS1 EX1 NEW1"|"CS1 NEW1 tt"|"CS1 CS2"|"CS1 EX1"|"CS1 NEW1"|"CS1 tt"|"CS2 EX1 NEW1"|"CS2 EX1 tt"|"CS2 NEW1 tt"|"CS2 EX1"|"CS2 NEW1"|"CS2 tt"|"EX1 NEW1"|"EX1 tt"|"NEW1 tt"|"CS1"|"CS2"|"EX1"|"NEW1"|"tt")
      Set="EXPERT1"
      ;;
    "GVG")
      Set="GVG"
      EXT_release=08/12/2014
      ;;
    "TGT")
      Set="TGT"
      EXT_release=24/08/2015
      ;;
    "OG")
      Set="OG"
      EXT_release=26/04/2016
      ;;
    "CFM")
      Set="GANGS"
      EXT_release=01/12/2016
      ;;
    "UNG")
      Set="UNGORO"
      EXT_release=06/04/2017
      ;;
    "ICC")
      Set="ICECROWN"
      EXT_release=10/08/2017
      ;;
    "LOOT")
      Set="LOOTAPALOOZA"
      EXT_release=07/12/2017
      ;;
    "GIL")
      Set="GILNEAS"
      EXT_release=12/04/2018
      ;;
    "BOT")
      Set="BOOMSDAY"
      EXT_release=07/08/2018
      ;;
    "TRL")
      Set="TROLL"
      EXT_release=04/12/2018
      ;;
    "DAL DRG ULD"|"DAL DRG"|"DAL ULD"|"DRG ULD")
      Set="YEAR_OF_THE_DRAGON"
      EXT_release=09/04/2019
      ;;
    "DAL")
      Set="DALARAN"
      EXT_release=09/04/2019
      ;;
    "ULD")
      Set="ULDUM"
      EXT_release=06/08/2019
      ;;
    "DRG")
      Set="DRAGONS"
      EXT_release=10/12/2019
      ;;
    "BT DMF SCH YOP"|"BT DMF SCH"|"BT DMF YOP"|"BT SCH YOP"|"DMF SCH YOP"|"BT DMF"|"BT SCH"|"DMF SCH"|"DMF YOD"|"SCH YOD")
      Set="YEAR_OF_THE_PHOENIX"
      EXT_release=09/04/2019
      ;;
    "BT")
      Set="BLACK_TEMPLE"
      EXT_release=07/04/2020
      ;;
    "SCH")
      Set="SCHOLOMANCE"
      EXT_release=06/08/2020
      ;;
    "DMF YOP"|"DMF"|"YOP")
      Set="DARKMOON_FAIRE"
      EXT_release=17/11/2020
      ;;
    *)
      CLASSES=""
      for card in $(echo "${Cards}" | jq -r ".[] | .id")
      do
        CLASS=$(jq -r ".[] | select(.id == \"$card\") | .cardClass" ${Latest_file})
        CLASSES+=($CLASS)
      done
      Unique_class=$(echo "${CLASSES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
      Count_Classes=$(echo ${Unique_class} | wc -w | awk '{print $1}')
      if [[ ${Count_Classes} == 1 ]]
      then
        Set=$(echo ${Unique_class} | sed -e "s/ //g")
      else
        Set="UNKNOWN"
        Date_Pack=$(date +%d/%m/%Y)-${TIMESTAMP}
        TIMESET="\"date\":\"$Date_Pack\","
        printf "\n[Warning] This set is unknown! Please consider updating the script: {$TIMESET\"set\":\"$Set\",\"cards\":$Cards}\n"
      fi
      ;;
  esac
  if [[ $ACTION == "convert" ]]
  then
    Date_Pack=${EXT_release}-${TIMESTAMP}
  else
    Date_Pack=$(date +%d/%m/%Y)-${TIMESTAMP}
  fi
  TIMESET="\"date\":\"$Date_Pack\","
  ALREADY_INJECTED=$(jq -r "select((.date == \"${Date_Pack}\") and (.set == \"${Set}\"))" ${JSONDB})
  if [[ -z $ALREADY_INJECTED ]]
  then
    printf "{$TIMESET\"set\":\"$Set\",\"cards\":$Cards}\n" >> ${JSONDB}
    if [[ $DEBUG == 1 ]]
    then
      printf "\n[Info] Pack added: {$TIMESET\"set\":\"$Set\",\"cards\":$Cards}\n"
    fi
    return 0
  else
    if [[ $DEBUG == 1 ]]
    then
      printf "\n[Info] Pack skipped: {$TIMESET\"set\":\"$Set\",\"cards\":$Cards}\n"
    fi
    return 1
  fi
}

fct_convert(){
  fct_set_collectable
  count_packs=0
  converted_packs=0
  CONVERT_PACKS=$(jq -c '.[]' $CONVERT_SOURCE)
  NBPACKS=$(echo "${CONVERT_PACKS}" | wc -l | awk '{print $1}')
  printf "Number of packs to convert: %5d\n" "${NBPACKS}"
  for Extract_packs in $CONVERT_PACKS
  do
    Cards=""
    PackSet=()
    Set=""
    TIMESTAMP=$(echo $Extract_packs | jq -r '.c[0]|.[0]')
    Pack_cards=$(echo $Extract_packs | jq -jr '.c[] | "\(.[1]):\(.[2]) "')
    fct_inject_json
    if [[ $? == 0 ]]
    then
      converted_packs=$[converted_packs + 1]
    fi
    count_packs=$[count_packs + 1]
    ProgressBar ${count_packs} ${NBPACKS}
  done 
  printf "\nNumber of packs converted:  %5d\n" "${converted_packs}"
}

fct_extract() {
  fct_set_collectable
  TIMESTAMPS=$(grep "cardId=" $LOGFILE | awk '{print $2}' | uniq)
  #TIMESTAMPS=$(grep "cardId=" $LOGFILE | grep "NEW" | awk '{print $2}' | uniq)
  count_packs=0
  imported_packs=0
  NBPACKS=$(echo "${TIMESTAMPS}" | wc -l | awk '{print $1}')
  for TIMESTAMP in $TIMESTAMPS
  do
    Cards=""
    PackSet=()
    Set=""
    TIMECARDS=$(awk -v timest=$TIMESTAMP '{if (($2 == timest) && ($(NF-3) ~ "cardId=")){printf $(NF-3)":"$(NF-1)" "}}' $LOGFILE | sed -e "s/cardId=//g")
    if [[ $(echo $TIMECARDS | wc -w | awk '{print $1}') == 5 ]]
    then
      Pack_cards=$(awk -v timest=$TIMESTAMP '{if (($2 == timest) && ($(NF-3) ~ "cardId=")){printf $(NF-3)":"$(NF-1)" "}}' $LOGFILE | sed -e "s/cardId=//g")
      fct_inject_json
      if [[ $? == 0 ]]
      then
      imported_packs=$[imported_packs + 1]
      fi
    fi
    count_packs=$[count_packs + 1]
    ProgressBar ${count_packs} ${NBPACKS}
  done 
  printf "\nNumber of packs imported: %5d\n" "${imported_packs}"
}

fct_get_sets(){
  Sets=$(jq -c ".[].set" ${Latest_file} | sort -u | grep -Ev "CORE|HERO_SKINS|HOF")
  Set_Match=$(jq -c ".[] | .set + \" \" + .id" ${Latest_file} | sed -e 's/_[0-9]\{3\}//' | sort -u | grep -Ev "CORE|HERO_SKINS|HOF")
}

fct_set_collectable() {
  if [[ ! -z $Extension ]]
  then
    case $Extension in 
      YEAR_OF_THE_PHOENIX)
        Collectable_cards=$(jq -r "sort_by(.rarity,.id) | .[] |  select((.set == \"YEAR_OF_THE_PHOENIX\") or (.set == \"BLACK_TEMPLE\") or (.set == \"SCHOLOMANCE\") or (.set == \"DARKMOON_FAIRE\")  or (.set == \"HOF\"))" ${Latest_file})
        ;;
      YEAR_OF_THE_DRAGON)
        Collectable_cards=$(jq -r "sort_by(.rarity,.id) | .[] |  select((.set == \"YEAR_OF_THE_DRAGON\") or (.set == \"DALARAN\") or (.set == \"ULDUM\") or (.set == \"DRAGONS\")  or (.set == \"HOF\"))" ${Latest_file})
        ;;
      *)
        Collectable_cards=$(jq -r "sort_by(.rarity,.id) | .[] |  select((.set == \"$Extension\") or (.set == \"HOF\"))" ${Latest_file})
        ;;
    esac
  else
    Collectable_cards=$(jq -r "sort_by(.id) | reverse | .[] | select((.set != \"CORE\") and (.set != \"HERO_SKINS\") and (.set != \"BOF\") and (.set != \"DEMON_HUNTER_INITIATE\"))" ${Latest_file})
  fi
}

fct_pity_ascii(){
  printf "| %16s | Total | Pity-timer |\n" "Card Type"
  echo "-----------------------------------------"
  for i in {0..5}
  do
    case $i in
      0)
        COLOR=${ORANGE}
        TITLE="GOLDEN LEGENDARY"
        ;;
      1)
        COLOR=${PURPLE}
        TITLE="GOLDEN EPIC"
        ;;
      2)
        COLOR=${BLUE}
        TITLE="GOLDEN RARE"
        ;;
      3)
        COLOR=${GREY}
        TITLE="GOLDEN COMMON"
        ;;
      4)
        COLOR=${ORANGE}
        TITLE="LEGENDARY"
        ;;
      5)
        COLOR=${PURPLE}
        TITLE="EPIC"
        ;;
    esac
    printf "| ${COLOR}%16s${NC} | %5d |  %3d / %3d |\n" "${TITLE}" ${Count_Type[$i]} ${PITY_TIMER[$i]} ${PITY_TIMER_INIT[$i]}
  done
  echo "-----------------------------------------"
}

fct_pity_html(){
  echo "<h2>Pity Timer</h2>
<table id="#Pity_timer">
  <tr> <th>Card Type</th> <th>Total</th> <th>Pity-timer</th> </tr>" >> $HTMLFILE
  for i in {0..5}
  do
    case $i in
      0)
        BACKGROUND=${YELLOW}
        COLOR=${ORANGE}
        TITLE="GOLDEN LEGENDARY"
        ;;
      1)
        BACKGROUND=${YELLOW}
        COLOR=${PURPLE}
        TITLE="GOLDEN EPIC"
        ;;
      2)
        BACKGROUND=${YELLOW}
        COLOR=${BLUE}
        TITLE="GOLDEN RARE"
        ;;
      3)
        BACKGROUND=${YELLOW}
        COLOR=${GREY}
        TITLE="GOLDEN COMMON"
        ;;
      4)
        BACKGROUND=#eee
        COLOR=${ORANGE}
        TITLE="LEGENDARY"
        ;;
      5)
        BACKGROUND=#eee
        COLOR=${PURPLE}
        TITLE="EPIC"
        ;;
    esac
    echo "  <tr style=\"background-color:${BACKGROUND};color:${COLOR}\" > <td>${TITLE}</td> <td>${Count_Type[$i]}</th> <td>${PITY_TIMER[$i]} / ${PITY_TIMER_INIT[$i]}</td> </tr>" >> $HTMLFILE
    done
  echo "  </tr>
</table>" >> $HTMLFILE
}

fct_display() {
  if [[ ${format} == "html" ]]
  then
    RED='#FF0000'
    ORANGE='#FFAC33'
    BLUE='#3933FF'
    PURPLE='#CA33FF'
    GREY='grey'
    YELLOW='#DCD230'
    NC='#FFFFFF'
  else
    RED='\033[0;31m'
    ORANGE='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    GREY='\033[1;30m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
  fi
  
  Count=1
  Count_Type=(0 0 0 0 0 0) 
  Count_Pack=0
  
  fct_set_collectable
  if [[ ! -z $Extension ]]
  then
    TO_DISPLAY=$(jq -c "select(.set == \"$Extension\")" ${JSONDB} | tail -${TAIL_PACKS}) 
  else
    TO_DISPLAY=$(tail -${TAIL_PACKS} ${JSONDB})
  fi
  if [[ -z $TO_DISPLAY ]]
  then
    echo "You have no packs to display"
  fi
  Pity_count=(-1 -1 -1 -1 -1 -1)
  NB_PACKS=$(echo "${TO_DISPLAY}" | wc -l | awk '{print $1}')
  if [[ $Display_Cards != "true" ]]
  then
    echo "Number of packs to scan: $NB_PACKS"
  fi
  for Pack_Arr in ${TO_DISPLAY}
  do
    Extension=$(echo $Pack_Arr | jq -r ".set")
    if [[ $Display_Cards == "true" ]]
    then
      if [[ ${format} == "html" ]]
      then
       printf "  <tr> <td><b>$[Count_Pack + 1]</b></td>" >> $HTMLFILE
      else
        printf "| %-18s " "${Extension}"
      fi
    fi
    HTML_LIST=""
    for card in $(echo $Pack_Arr | jq -c ".cards[]")
    do
      Card_id=$(echo $card | jq -r '.id')
      if [[ $(echo $card | jq -r '.type') == "NORMAL" ]]
      then
        Type=""
      else
        Type="G"
      fi
      card_extract=$(echo "${Collectable_cards}" | jq -r "select(.id == \"$Card_id\") | .name + \"+\" + .rarity")
      name=$(echo "${card_extract}" | cut -d'+' -f1)
      rarity=$(echo "${card_extract}" | cut -d'+' -f2)
      case $rarity in
        "COMMON")
          COLOR=${GREY}
          if [[ ${Type} == "G" ]]
          then
            Pity_count[3]=${PITY_TIMER_INIT[3]}
            Count_Type[3]=$[Count_Type[3] + 1]
          fi
          ;;
        "RARE")
          COLOR=${BLUE}
          if [[ ${Type} == "G" ]]
          then
            Pity_count[2]=${PITY_TIMER_INIT[2]}
            Count_Type[2]=$[Count_Type[2] + 1]
          fi
          ;;
        "EPIC")
          COLOR=${PURPLE}
          if [[ ${Type} == "G" ]]
          then
            Pity_count[1]=${PITY_TIMER_INIT[1]}
            Count_Type[1]=$[Count_Type[1] + 1]
          else
            Pity_count[5]=${PITY_TIMER_INIT[5]}
            Count_Type[5]=$[Count_Type[5] + 1]
          fi
          ;;
        "LEGENDARY")
          COLOR=${ORANGE}
          if [[ ${Type} == "G" ]]
          then
            Pity_count[0]=${PITY_TIMER_INIT[0]}
            Count_Type[0]=$[Count_Type[0] + 1]
          else
            Pity_count[4]=${PITY_TIMER_INIT[4]}
            Count_Type[4]=$[Count_Type[4] + 1]
          fi
          ;;
      esac
      if [[ $Display_Cards == "true" ]]
      then
        if [[ ${format} == "html" ]]
        then
          if [[ ${Type} == "G" ]]
          then
            printf " <td><video width=\"128\" height=\"184\" controls loop><source src=\"https://cards.hearthpwn.com/enUS/webms/${Card_id}.webm\" type=\"video/webm\"></video></td>" >> $HTMLFILE
            HTML_LIST="$HTML_LIST<b><font color=${RED}>[G]</font><font color=${COLOR}> ${name}</font></b><br>"
          else
            printf "<td><img src=\"https://cards.hearthpwn.com/enUS/${Card_id}.png\" style=\"width:128px;height:184px;\"></td>" >> $HTMLFILE
            #HTML_LIST="$HTML_LIST<p style=\"color:${COLOR};\">${name}</p>"
            HTML_LIST="$HTML_LIST<font color=${COLOR}>${name}</font><br>"
          fi
        else
          printf "| ${COLOR}%-27s${YELLOW}%1s${NC} " "${name}" "${Type}"
        fi
      fi
    done
    Count_Pack=$[Count_Pack + 1]
    if [[ $Display_Cards == "true" ]]
    then
      if [[ ${format} == "html" ]]
      then
        printf "<td><b>${Extension}</b><br>${HTML_LIST}</td></tr>\n" >> ${HTMLFILE}
        ProgressBar ${Count_Pack} ${NB_PACKS}
      else
        printf "|\n"
      fi
    else
      ProgressBar ${Count_Pack} ${NB_PACKS}
    fi
    if [[ $Pitytimer == "true" ]]
    then
      for i in {0..5}
      do
        if [[ ${Pity_count[$i]} == '-1' ]]
        then
          PITY_TIMER[$i]=$[PITY_TIMER[$i] - 1]
        else
          PITY_TIMER[$i]=${Pity_count[$i]}
        fi
      done
      #echo ${PITY_TIMER[@]}
    fi
    Pity_count=(-1 -1 -1 -1 -1 -1)
  done 
  if [[ ${format} == "html" ]]
  then
    printf "</table>\n
<h2>Summary</h2>
<table>
  <tr>
    <td>Number of packs opened</td> <td>${Count_Pack}</td>
  </tr>
</table>" >>${HTMLFILE}
  else
    printf "\n-----------------------------------------\n"
    echo "Number of packs opened: $Count_Pack"
    echo "-----------------------------------------"
  fi
  if [[ $Pitytimer == "true" ]]
  then
    if [[ ${format} == "html" ]]
    then
      fct_pity_html
    else
      fct_pity_ascii
    fi
  fi
  if [[ ${format} == "html" ]]
  then
    echo "</html>" >> ${HTMLFILE}
    if [[ $(dirname ${HTMLFILE}) == "." ]]
    then
      HTMLFILE="$(pwd)/$(basename ${HTMLFILE})"
    fi
    echo -e "\nURL to Access the HTML file: file://${HTMLFILE}\n"
    open file://${HTMLFILE}
  fi
}

# Main
Script_name=$(basename $0 .sh)
while getopts ":a:d:e:f:F:j:l:L:s:t::pPW" opt; do
  case ${opt} in
    a)
      ACTION=$OPTARG
      ;;
    e)
      Extension=${OPTARG}
      ;;
    d)
      DEBUG=1
      if [[ ${OPTARG} == "debug" ]]
      then
        set -vx
      fi
      ;;
    f)
      format=$OPTARG
      ;;
    j)
      JSONDB=$OPTARG
      ;;
    F)
      Local_folder=${OPTARG}
      ;;
    l)
      LOGFILE=$OPTARG
      ;;
    L)
      URL_LANG=${OPTARG}
      ;;
    p)
      Pitytimer=true
      ;;
    P)
      Pitytimer=true
      Display_Cards=false
      ;;
    s)
      CONVERT_SOURCE=${OPTARG}
      ;;
    t)
      TAIL_PACKS=${OPTARG:-20}
      ;;
    W)
      WAIT=true
      ;;
    *) 
      fct_usage
      ;;
  esac
done

LOGFILE=${LOGFILE:-/Applications/Hearthstone/Logs/Achievements.log}
Local_folder=${Local_folder:-.}
Display_Cards=${Display_Cards:-"true"}
URL_LANG=${URL_LANG:-'enUS'}
JSONDB=${JSONDB:-$Local_folder/$Script_name.json}
JSON_URL='https://api.hearthstonejson.com/v1'
Latest=$(curl -s $JSON_URL/ | grep href | cut -d'"' -f2 | cut -d'/' -f3 | sort -nu | tail -1)
Latest_file=${Local_folder}/cards_collectible_${Latest}_${URL_LANG}.json
PITY_NORMAL_EPIC=10
PITY_NORMAL_LEGENDARY=40
PITY_GOLDEN_COMMON=26
PITY_GOLDEN_RARE=30
PITY_GOLDEN_EPIC=158
PITY_GOLDEN_LEGENDARY=437
#PITY_TIMER=(GOLDEN_LEGENDARY GOLDEN_EPIC GOLDEN_RARE GOLDEN_COMMON NORMAL_LEGENDARY NORMAL_EPIC)
PITY_TIMER_INIT=($PITY_GOLDEN_LEGENDARY $PITY_GOLDEN_EPIC $PITY_GOLDEN_RARE $PITY_GOLDEN_COMMON $PITY_NORMAL_LEGENDARY $PITY_NORMAL_EPIC)
PITY_TIMER=(${PITY_TIMER_INIT[@]})
#echo ${PITY_TIMER[@]}

if [[ ! -d $Local_folder ]]
then
  mkdir -p $Local_folder
fi
if [[ ! -f $JSONDB ]]
then
  touch $JSONDB
fi
NB_PACKS=$(wc -l $JSONDB | awk '{print $1}')
TAIL_PACKS=${TAIL_PACKS:-$NB_PACKS}

if [[ ! -f ${Latest_file} ]] || [[ ! -s ${Latest_file} ]]
then
    echo "Download ${Latest} (${URL_LANG}) to ${Latest_file}"
    /usr/bin/curl -s -k -L "${JSON_URL}/${Latest}/${URL_LANG}/cards.collectible.json" | jq -r '.' > ${Latest_file} 2>/dev/null
    if [[ $? != 0 ]] || [[ ! -f ${Latest_file} ]] || [[ ! -s ${Latest_file} ]]
    then
        echo "[Error] Unable to download JSON patch ${Latest} from: ${JSON_URL}/${Latest}/${URL_LANG}/cards.collectible.json"
        exit 10
    fi
fi

fct_get_sets
if [[ ! -z $Extension ]]
then
  Ext_valide=$(echo ${Sets} | grep -w $Extension)
  if [[ -z ${Ext_valide} ]]
  then
    echo "Invalid Extension: ${Extension}"
    echo -e "Please set a valid extension:\n${Sets}"
    exit 2
  fi
  HTMLFILE=${Local_folder}/${Script_name}_${Extension}.html
else
  HTMLFILE=${Local_folder}/${Script_name}.html
fi

if [[ "${Pitytimer}" == "true" ]] && [[ -z $Extension ]]
then
  echo "Missing Extension name [-e extension] to get the Pity Timers"
  fct_usage
fi

case $ACTION in
  display)
    if [[ $format == "html" ]]
    then
      echo "<html><style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
  background-color: #eee;
  text-align: center;
}
th {
  color: white;
  background-color: black;
}
</style>
<h2>Card Display</h2>
<table style=\"width:100%\">
<tr> <th>Pack Number</th> <th>Card #1</th> <th>Card #2</th> <th>Card #3</th> <th>Card #4</th> <th>Card #5</th> <th>Summary</th> </tr>" > $HTMLFILE
    fi
    fct_display
    ;;
  extract)
    Extension=""
    fct_extract
    ;;
  convert)
    if [[ -z $CONVERT_SOURCE ]]
    then
      echo "Error: please specify the source to convert"
      fct_usage
    fi
    fct_convert
    ;;
  *)
    fct_usage
    ;;
esac
