#!/usr/bin/bash

if [ $# -lt 1 ]; then
        echo "Usage: filetest filename"
        exit 1
fi

#------------------------------GLOBAL VARIABLES--------------------------------
FILE=$1
strMenu=$'\n-----------------------MENU------------------------------\n\n1.) insert\n2.) delete\n3.) search\n4.) update_name\n5.) update_amount\n6.) print_amount\n7.) print_all\n\n
enter number from 1-7 or CTRL+D to exit: '
pickedName=""
recordCheck=""
amountCheck="" 
#________________________________________________________________________________


function checkAmountInput() {
	local amount=$1
	if [[ $amount =~ ^[0-9]+$ ]]; then 
  		return 0 
	else
  		echo "invalid input The amout you enterd is NOT allowed(numbers only)."
  		return 1
	fi
}

function checkRecInput() {
	local cdName="$1"
	if [[ "$cdName" =~ ['!@#$%^&*()_+'] ]]; then
  		echo "invalid input The name you enterd is NOT allowed(record name must contain letters or numbers no special character)."
  		return 1
	else
  		return 0		  		
	fi
}

#Search function for INSERT DELETE OR UPDATED
function find() {
	local str="$1"
	local records=$(cut -f1 -d "," $FILE | grep -i "$str" | sort)
	local numOfResult=$(grep -i "$str" $FILE  | wc -l)

	if [ $numOfResult -le 0 ]; then   #name not exists
		return 1
	elif [ $numOfResult -eq 1 ]; then #only one choice
		pickedName="$records"
		return 0
	else 				   #multiple choices
		cut -f1 -d "," $FILE | grep -i "$1" | sort > temp.txt
		OLDIFS=$IFS #save the default value
		IFS=$'\n'
		PS3="Pick a name or ctrl+D to exit: "
		select record in $records; do
    			local choice=$REPLY
    			pickedName=$(sed $choice!d temp.txt) #get the line
    			rm temp.txt
    			IFS=$OLDIFS #restore the default value
    			PS3="$strMenu"
    			break
		done
	fi
}

function insert() {
	local cdName="$1"
	local amount=$2
	find "$cdName" 
	if [ $? -eq 0 ]; then 
		updateAmount "$pickedName" $amount
	else
		echo $cdName", "$amount>>$FILE
		echo $cdName "new record added to the store"
		log "Insert" "Success"
	fi
}

function delete() {
	local cdName="$1"
	local amount=$2
	find "$cdName" 
	if [ $? -eq 0 ]; then 
		updateAmount "$pickedName" -$amount
		log "Delete" "Success"
		echo $cdName " record deleted successfully"
	else
		echo $cdName "record not found no record to delete"
		log "Delete" "Faliure"
	fi
}

function search() {
	local var=$(grep -i $1 $FILE)
	if [ "$var" != "" ]; then
		echo "resulte: "
		grep -i $1 $FILE | sort
		log "Search" "Success"	
	else
		echo "the "$1" record not found"
		log "Search" "Faliure"
	fi
}

function updateName() {
	local cdName="$1"
	find "$cdName"
	if [ $? -eq 0 ]; then 
		local oldName="$pickedName"
		local newName=$2
		sed -i "s/$oldName/$newName/I" $FILE
		echo "record name " $pickedName " updated to "$newName
		log "UpdateName" "Success"
	else
		echo $pickedName "not found no record to update"
		log "UpdateName" "Faliure"
	fi
}

function updateAmount() {
	local cdName="$1"
	local amount=$2
	find "$cdName"
	if [ $? -eq 0 ]; then 
		local oldAmount=$(grep -i "$pickedName" $FILE | awk -F", " '{print $NF}')
		let newAmount=$oldAmount+$amount
		local oldLine=$pickedName", "$oldAmount
		local newLine=$pickedName", "$newAmount 
		if [ $newAmount -gt 0 ]; then
			sed -i "s/$oldLine/$newLine/I" $FILE
			echo $pickedName "record amount updated"
		elif [ $newAmount -eq 0 ]; then
			sed -i "s/$oldLine//" $FILE #remove the whole line
			sed -i '/^$/d' $FILE #clear the empty space
		else
			echo "can't delete more then $oldAmount"
		fi
	else
		echo "record not found"
		log "updateAmount" "Faliure"
	fi
}

function printAmount() {
	if [ -s $FILE ]; then
		local numbers=$(cat $FILE | awk -F"," '{print $NF}') #using awk to get only the numbers after the "," delimiter
		echo $numbers > tp.txt 
		local num=$(cat tp.txt | numsum -r) #writh the numbers to a temporary file and sum the numbers with numsum function(downloaded package)
		rm tp.txt
		echo "you have "$num" records in total"
	else
		echo "store is empty." 
	fi
	log "PrintAmount" $num
}

function printAll() {
	OLDIFS=$IFS
	if [ -s $FILE ]; then
		echo "all records:"
		echo "-----------------------------------------------------------"
		sort $FILE
	else
		echo "store is empty." 
	fi
	cat $FILE | while read line 
	do
		IFS=$'\n'
		log "PrintAll" $line
	done
	IFS=$OLDIFS
}

function log() {
	local action=$1
	local status=$2
	local amount=$3
	local d=$(date +"%d/%m/%Y")
	local t=$(date +"%T")
	now=$d" "$t
	if [ $# -eq 3 ]; then
		echo $now" "$action" "$status" "$amount>> recordFile_log
		return
	fi
	echo $now" "$action" "$status>> recordFile_log
}

clear
echo "##################################"
echo "#                                #"
echo "# welcome to the records library #"
echo "#                                #"
echo "##################################"
echo
echo "  This library action are:"
echo
PS3="$strMenu"
select replay in insert delete search update_name update_amount print_amount print_all; do
clear
        case $replay in
                insert)
                       echo "-----------------------Insert------------------------------"
                       read -p "enter the record name: " cdName
			read -p "enter the amount: " amount
			checkRecInput "$cdName"
			recordCheck=$?
			checkAmountInput $amount
			amountCheck=$?
			if [[ $recordCheck -eq 1 || $amountCheck -eq 1 ]]; then
				echo "try agine"
				log "Insert" "Faliure"
			else
				insert "$cdName" $amount
			fi
			echo "-----------------------------------------------------------"
                       ;;
                delete)
                       echo "-----------------------Delete------------------------------"
                       read -p "enter the record name: " cdName
			read -p "enter the amount: " amount
                       delete "$cdName" $amount
                       echo "-----------------------------------------------------------"
                       ;;
                search)
                       echo "-----------------------Search------------------------------"
                       read -p "enter the record name: " cdName
                       search "$cdName"
                       echo "-----------------------------------------------------------"
                       ;;
                update_name)
                       echo "-----------------------Update Name-------------------------"
                       read -p "enter the record name: " oldName
			read -p "enter the new name: " newName
			checkRecInput "$newName"
			recordCheck=$?
			if [[ $recordCheck1 -eq 1 ]]; then
				echo "try agine"
				log "UpdateName" "Faliure"
			else
				 updateName "$oldName" "$newName"
			fi
                       echo "----------------------------------------------------------"
                       ;;
                update_amount)
                       echo "-----------------------Update Amount----------------------"
                       read -p "enter the record name you want to update: " cdName
			read -p "enter the amount: " amount
			checkAmountInput $amount
			amountCheck=$?
			if [[ $amountCheck -eq 1 ]]; then
				echo "try agine"
				"UpdateAmount" "Faliure"
			else
				updateAmount "$cdName" "$amount"
			fi
                       echo "---------------------------------------------------------"
                       ;;
                print_amount)
                       echo "-------------------Print Amount--------------------------"
                       printAmount
                       echo "---------------------------------------------------------"
                       ;;
                print_all)
                       echo "-------------------print All-----------------------------"
                       printAll
                       echo "---------------------------------------------------------"
                       ;;
                *)
                       echo "---------------------------------------------------------"
                       Invalid choice
                       echo "---------------------------------------------------------"
                       exit 1
                       ;;
        esac
done


