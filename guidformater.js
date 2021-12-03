const guidtestin = '96fd8d5a998a1b92de37e6be90e8673e'
const guidtestoutCheck = '96fd8d5a-998a-1b92-de37-e6be90e8673e'
console.log(process.argv);
if(process.argv.length>2 && process.argv[2].length==32){
    const guidtestout = format(process.argv[2]);
    console.log(guidtestout);
}else{
    console.log(`Run Test with:`);
    console.log(guidtestin);
    const guidtestout = format(guidtestin);
    console.log(guidtestout);
    (guidtestout==guidtestoutCheck)?console.log('OK'):console.log('NOK');
}

function format(input){
    return `${input.substr(0,8)}-${input.substr(8,4)}-${input.substr(12,4)}-${input.substr(16,4)}-${input.substr(20,12)}`;
}