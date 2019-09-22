set supported_version0 2019.1
set supported_version1 2019.1.1
set supported_version2 2019.1.2

set curr [version -short -quiet -verbose]
puts "Current version is ${curr}."
if {${curr} == ${supported_version0} || 
	${curr} == ${supported_version1} ||
	${curr} == ${supported_version2}} {
	puts "Vivado version: Pass"
	exit 0
} else {
	puts "Error: Vivado version is not proper."
	puts "Please visit https://www.xilinx.com/support/download.html"
	puts "Please donwload propoer Vivado Design Suite."
	exit -1
}

