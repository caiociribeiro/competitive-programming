$javaSource = "Main.java"
$javaClass = "Main"
$testDir = "tests"

# compile
Write-Host "Compiling $javaSource..." -ForegroundColor Cyan
javac $javaSource

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to compile. Aborting..." -ForegroundColor Red
    exit
}
Write-Host "Compiled successfully" -ForegroundColor Green

$inputFiles = Get-ChildItem "$testDir\*.in" | Sort-Object { [int]($_.BaseName) }

if ($inputFiles.Count -eq 0) {
    Write-Host "No test file found." -ForegroundColor Yellow
    exit
}

$countPass = 0
$countFail = 0

# start general stopwatch
$totalSw = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($inputFile in $inputFiles) {
    $testName = $inputFile.BaseName 
    $expectedFile = Join-Path $testDir "$testName.out"

    if (-not (Test-Path $expectedFile)) {
        Write-Host "Test $testName : .out file not found" -ForegroundColor Yellow
        continue
    }

    # start test specific stopwatch
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # execute
    $actualOutput = cmd /c "java -cp . $javaClass < `"$($inputFile.FullName)`"" 2>&1
    
    $sw.Stop()

    $ms = [math]::Round($sw.Elapsed.TotalMilliseconds)
    $timeStr = "[$ms ms]"
    
    $timeColor = if ($ms -gt 1000) { "Yellow" } else { "DarkGray" }

    $expectedOutput = Get-Content $expectedFile

    # compare outputs
    $diff = Compare-Object -ReferenceObject $expectedOutput -DifferenceObject $actualOutput -CaseSensitive -SyncWindow 0

    Write-Host -NoNewline "Test $testName : "

    if ($null -eq $diff) {
        Write-Host -NoNewline "PASSED " -ForegroundColor Green
        Write-Host $timeStr -ForegroundColor $timeColor
        $countPass++
        
        $debugFile = Join-Path $testDir "$testName.my.out"
        if (Test-Path $debugFile) { Remove-Item $debugFile }

    }
    else {
        Write-Host -NoNewline "FAILED " -ForegroundColor Red
        Write-Host $timeStr -ForegroundColor $timeColor
        $countFail++

        $debugFile = Join-Path $testDir "$testName.my.out"
        $actualOutput | Set-Content -Path $debugFile
        Write-Host "   [!] See: $testName.my.out" -ForegroundColor Gray
    }
}

$totalSw.Stop()

$totalSeconds = "{0:N2}" -f $totalSw.Elapsed.TotalSeconds

Write-Host "$countPass Passed " -ForegroundColor Green -NoNewline
Write-Host "| " -NoNewline
Write-Host "$countFail Failed " -ForegroundColor ($countFail -eq 0 ? "Green" : "Red") -NoNewline
Write-Host "| Total Time: ${totalSeconds}s" -ForegroundColor Cyan