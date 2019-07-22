
# BASE ADDRESS
BA=0x4402

# TIME UNIT
FN=TIME_UNIT
FA=010

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo -n "WRITING $1 TO [${FN}-REG01]: "
${RWAXI}/rwaxi -a ${BA}${FA}1 -w $1
echo "-----------------------------------------------------------"

echo -n "READING FROM [${FN}-REG01]: "
${RWAXI}/rwaxi -a ${BA}${FA}1
echo "-----------------------------------------------------------"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
