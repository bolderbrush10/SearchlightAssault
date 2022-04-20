export PATH=$PATH:"C:\Program Files\7-Zip"
if ! command -v 7z &> /dev/null ; then
  echo "Could not find 7zip in path: "
  echo $PATH
  exit
fi

oldVersion=$(cat version.txt)
echo "${oldVersion}"
if [ $# -eq 0 ] ; then
    printf "\nArg 1: Changelog messages as a semicolon-delimited \"string\"\r\nArg 2: (optional) '1' if minor version should be rev'd\r\n\t'2' if this should just amend an existing release (input empty \"\" for first arg)"
    exit
fi

IFS_SAVE=$IFS
IFS='.'          # Change IFS to split on new line
version=($oldVersion) # split to array
if [ $# -eq 1 ] ; then
  (( version[2]++ ))
  newVersion="${version[*]}"
elif [ $2 -eq 1 ] ; then
  version[2]=0
  (( version[1]++ ))
  newVersion="${version[*]}"
elif [ $2 -eq 2 ] ; then
  newVersion=$oldVersion
fi

clDelim="---------------------------------------------------------------------------------------------------"
echo ${clDelim} > tempCL.txt
printf "Version: " >> tempCL.txt
printf "${newVersion}" >> tempCL.txt
printf "\nDate: " >> tempCL.txt
printf '%(%Y-%m-%d)T' -1  >> tempCL.txt
if [ $2 -ne 2 ] ; then
  printf "\n  Changes:\n" >> tempCL.txt
else
  printf "\n  (No changelog update)\n" >> tempCL.txt
fi

IFS=';'          # Change IFS to split on semicolon
splitMessage=($1)

for (( i=0; i<${#splitMessage[@]}; i++ ))
do
  printf "    - ${splitMessage[$i]}\n" >> tempCL.txt
done

cat tempCL.txt

echo "Proceed? (y/n)"
read approve

if [ "${approve,,}" == "y" ]; then #convert user input to lower case with ,,

  if [ $2 -ne 2 ] ; then
    cat changelog.txt >> tempCL.txt
    mv tempCL.txt changelog.txt 
    echo "${newVersion}" > version.txt
    sed -i '3s/.*/  "version": "'${newVersion}'",/' info.json
  else
    rm "../SearchlightAssault_${newVersion}.zip"
    rm tempCL.txt
  fi
  cd ..
  7z a "SearchlightAssault_${newVersion}.zip" SearchlightAssault -r -xr@SearchlightAssault/exclude.txt
  7z rn "SearchlightAssault_${newVersion}.zip" SearchlightAssault SearchlightAssault_${newVersion}
  rm C:/Users/ben/AppData/Roaming/Factorio/mods/SearchlightAssault*
  cp "SearchlightAssault_${newVersion}.zip" C:/Users/ben/AppData/Roaming/Factorio/mods
  cd SearchlightAssault
  echo "Done"
else
  rm tempCL.txt
  echo "Aborted"
fi

# Restore IFS after changing
IFS=$IFS_SAVE