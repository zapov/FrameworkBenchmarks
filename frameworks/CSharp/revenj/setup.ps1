param($action)

if (!$TROOT) {
  $TROOT = "C:\FrameworkBenchmarks\frameworks\CSharp\revenj"
}
if (!$DBHOST) {
  $DBHOST = "localhost"
}

$msbuild = $Env:windir + "\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe"
$java=$Env:JAVA_HOME + "\bin\java"
$dslclc=$TROOT + "\dsl-clc.jar"
$sln=$TROOT + "\Revenj.Bench.sln"
$revenj=$TROOT + "\exe\Revenj.Http.exe"

echo "Stopping existing Revenj.Http"
Stop-Process -Name "Revenj.Http*" -ErrorAction 'SilentlyContinue' | Out-Null

if ($action -eq 'start') {

	echo "Cleaning up..."
	If (Test-Path $TROOT/exe) {
	  rmdir $TROOT/exe -recurse -force
	}
	If (Test-Path $TROOT/tmp) {
	  rmdir $TROOT/tmp -recurse -force
	}
	if (Test-Path $TROOT/dsl-clc.jar) {
	  rm $TROOT/dsl-clc.jar
	}

	echo "Download DSL compiler client"
	$client = new-object System.Net.WebClient
	$client.DownloadFile( "https://github.com/ngs-doo/dsl-compiler-client/releases/download/1.3.0/dsl-clc.jar", $dslclc )

	echo "Setting up the directories"
	mkdir $TROOT/exe
	mkdir $TROOT/tmp

	echo "Compiling the server model, and downloading dependencies..."
	&$java -jar $dslclc temp=$TROOT/tmp/ dsl=$TROOT/Revenj.Bench manual-json revenj=$TROOT/exe/ServerModel.dll no-prompt compiler dependencies:revenj=$TROOT/exe download

	echo "Compiling the benchmark project..."
	&$msbuild $sln /p:Configuration=Release /t:Rebuild

	echo "Copying the configuration template"
	$template = cat $TROOT/Revenj.Http.exe.config.template
	$template.Replace("server=localhost", "server=" + $DBHOST) > $TROOT/exe/Revenj.Http.exe.config

	echo "Starting Revenj..."
	Start-Process $revenj
}
