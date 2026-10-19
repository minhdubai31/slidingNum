param(
    [string]$AndroidJar = $env:ANDROID_JAR,
    [string]$JavaHome = $env:JAVA_HOME
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
if (!$AndroidJar) {
    $sdk = $env:ANDROID_HOME
    if (!$sdk) { $sdk = $env:ANDROID_SDK_ROOT }
    if (!$sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
    $platform = Get-ChildItem (Join-Path $sdk 'platforms') -Directory -ErrorAction SilentlyContinue |
        Where-Object Name -Match '^android-\d+$' |
        Sort-Object { [int]($_.Name -replace 'android-', '') } -Descending |
        Select-Object -First 1
    if ($platform) { $AndroidJar = Join-Path $platform.FullName 'android.jar' }
}
if (!$AndroidJar -or !(Test-Path -LiteralPath $AndroidJar -PathType Leaf)) {
    throw 'Android SDK platform missing. Install an SDK platform, or pass -AndroidJar <path to android.jar>.'
}
$javac = if ($JavaHome) { Join-Path $JavaHome 'bin/javac.exe' } else { 'javac.exe' }
$jar = if ($JavaHome) { Join-Path $JavaHome 'bin/jar.exe' } else { 'jar.exe' }
if (!(Get-Command $javac -ErrorAction SilentlyContinue) -or !(Get-Command $jar -ErrorAction SilentlyContinue)) {
    throw 'JDK 17+ missing. Set JAVA_HOME or pass -JavaHome <JDK folder>.'
}
$api = Join-Path $here 'lib/godot-plugin-api.jar'
if (!(Test-Path -LiteralPath $api)) { throw "Missing Godot plugin API: $api" }
$work = Join-Path ([IO.Path]::GetTempPath()) ('imagepicker-' + [guid]::NewGuid())
$output = [IO.Path]::GetFullPath((Join-Path $here '../plugins/ImagePicker.aar'))
try {
    $classes = New-Item (Join-Path $work 'classes') -ItemType Directory -Force
    $sources = @(Get-ChildItem (Join-Path $here 'src/com/minhth/slidepuzzle/imagepicker/*.java') | ForEach-Object FullName)
    & $javac --release 17 -cp "$AndroidJar;$api" -d $classes.FullName @sources
    if ($LASTEXITCODE -ne 0) { throw 'Java compilation failed.' }
    & $jar cf (Join-Path $work 'classes.jar') -C $classes.FullName .
    if ($LASTEXITCODE -ne 0) { throw 'Packing classes.jar failed.' }
    @'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.minhth.slidepuzzle.imagepicker">
    <application>
        <meta-data android:name="org.godotengine.plugin.v2.ImagePicker" android:value="com.minhth.slidepuzzle.imagepicker.ImagePickerPlugin" />
    </application>
</manifest>
'@ | Set-Content (Join-Path $work 'AndroidManifest.xml') -Encoding UTF8
    & $jar cf (Join-Path $work 'ImagePicker.aar') -C $work AndroidManifest.xml -C $work classes.jar
    if ($LASTEXITCODE -ne 0) { throw 'Packing ImagePicker.aar failed.' }
    Copy-Item (Join-Path $work 'ImagePicker.aar') $output -Force
    Write-Host "Built $output"
} finally {
    # Only remove this invocation's unique temporary directory.
    if ((Split-Path $work -Parent) -eq [IO.Path]::GetTempPath().TrimEnd('\')) {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}
