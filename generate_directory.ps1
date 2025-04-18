# Define folders you want to include
$INCLUDE_FOLDERS = @("data", "tools")

function Get-TreeHtml {
    param(
        [string]$basePath,
        [string]$relativePath = ""
    )

    $html = ""

    try {
        $entries = Get-ChildItem -Path $basePath | Sort-Object Name
        if ($entries.Count -gt 0) {
            $html += "<ul class='file-tree'>`n"

            foreach ($entry in $entries) {
                $fullPath = $entry.FullName
                $entryRelativePath = if ($relativePath) { "$relativePath/$($entry.Name)" } else { $entry.Name }
                $entryPathForUrl = $entryRelativePath.Replace("\", "/")

                # Make all paths relative to root
                $rootRelativePath = "/$entryPathForUrl"

                if ($entry.PSIsContainer) {
                    $html += "  <li class='directory'>"
                    $html += "<span class='folder-toggle'></span>"
                    $html += "<a href='$rootRelativePath' class='folder-link' data-path='$rootRelativePath'>"
                    $html += "<span class='folder'>$($entry.Name)/</span></a>"

                    $subTree = Get-TreeHtml -basePath $fullPath -relativePath $entryRelativePath
                    if ($subTree) {
                        $html += "$subTree"
                    }
                    $html += "</li>`n"
                }
                else {
                    $html += "  <li class='file'>"
                    $html += "<a href='$rootRelativePath' class='file-link' data-path='$rootRelativePath'>"
                    $html += "<span class='file-name'>$($entry.Name)</span></a>"
                    $html += "</li>`n"
                }
            }

            $html += "</ul>`n"
        }
    }
    catch {
        # Handle permission errors by ignoring the inaccessible directories
        Write-Host "Error accessing $basePath : $_" -ForegroundColor Yellow
    }

    return $html
}

function Get-DirectoryStructureHtml {
    param(
        [string]$basePath = "."
    )

    $repoUrl = "https://backoffice-universe.teknologipendidikan.or.id" # Update this to your repo URL

    $css = @"
<style>
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
        line-height: 1.6;
        margin: 0;
        padding: 20px;
        color: #24292e;
        background-color: #f6f8fa;
    }
    .container {
        max-width: 1200px;
        margin: 0 auto;
        background-color: white;
        border-radius: 6px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        padding: 20px;
    }
    h1 {
        color: #24292e;
        border-bottom: 1px solid #e1e4e8;
        padding-bottom: 10px;
        margin-top: 0;
    }
    h2 {
        color: #0366d6;
        margin-top: 30px;
        font-size: 1.5em;
        display: flex;
        align-items: center;
    }
    h2:before {
        content: "📁";
        margin-right: 8px;
    }
    .file-tree {
        list-style-type: none;
        padding-left: 18px;
        margin: 8px 0;
    }
    .file-tree li {
        position: relative;
        padding: 3px 0;
    }
    .folder {
        font-weight: 600;
        color: #0366d6;
    }
    .file-name {
        color: #24292e;
    }
    .directory {
        position: relative;
    }
    .directory::before {
        content: "";
        position: absolute;
        left: -18px;
        top: 10px;
        width: 10px;
        height: 10px;
        border-radius: 1px;
        border-left: 1px solid #d1d5da;
        border-bottom: 1px solid #d1d5da;
    }
    .file::before {
        content: "📄";
        margin-right: 5px;
        font-size: 14px;
        opacity: 0.7;
    }
    a {
        text-decoration: none;
        color: inherit;
        display: inline-block;
    }
    a:hover {
        text-decoration: underline;
    }
    .file-link:hover .file-name {
        color: #0366d6;
    }
    .folder-link:hover .folder {
        text-decoration: underline;
    }
    .directory-content {
        padding-left: 20px;
        border-left: 1px solid #eaecef;
        margin-left: 10px;
    }
    .timestamp {
        font-size: 0.85em;
        color: #6a737d;
        margin-top: 40px;
        text-align: center;
        border-top: 1px solid #eaecef;
        padding-top: 20px;
    }
    .repo-link {
        display: inline-block;
        margin-top: 10px;
        background-color: #f6f8fa;
        border: 1px solid #e1e4e8;
        border-radius: 6px;
        padding: 6px 12px;
        font-size: 14px;
        color: #0366d6;
    }
    .repo-link:hover {
        background-color: #f1f4f8;
        text-decoration: none;
    }
    .folder-toggle {
        display: inline-block;
        width: 14px;
        height: 14px;
        margin-right: 5px;
        cursor: pointer;
        position: relative;
    }
    .folder-toggle:before {
        content: "+";
        display: inline-block;
        width: 14px;
        height: 14px;
        text-align: center;
        line-height: 12px;
        font-size: 14px;
        background-color: #f6f8fa;
        border: 1px solid #d1d5da;
        border-radius: 3px;
    }
    .directory.expanded .folder-toggle:before {
        content: "-";
    }
    .directory ul {
        display: none;
    }
    .directory.expanded ul {
        display: block;
    }
    .search-container {
        margin-bottom: 20px;
    }
    .search-input {
        padding: 8px 12px;
        border: 1px solid #d1d5da;
        border-radius: 6px;
        width: 100%;
        font-size: 14px;
        box-sizing: border-box;
    }
    .search-input:focus {
        outline: none;
        border-color: #0366d6;
        box-shadow: 0 0 0 3px rgba(3, 102, 214, 0.3);
    }
</style>
"@

    $js = @"
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Make all directories collapsed by default
        const directories = document.querySelectorAll('.directory');
        directories.forEach(dir => {
            dir.classList.add('expanded'); // Start expanded
        });

        // Add click handler for folder toggles
        document.addEventListener('click', function(e) {
            if (e.target.classList.contains('folder-toggle') || e.target.closest('.folder-toggle')) {
                const dir = e.target.closest('.directory');
                dir.classList.toggle('expanded');
                e.preventDefault();
            }
        });

        // Handle file clicks
        const fileLinks = document.querySelectorAll('.file-link');
        fileLinks.forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                const path = this.getAttribute('data-path');
                // Use root-relative paths
                window.open(path, '_blank');
            });
        });

        // Handle folder clicks
        const folderLinks = document.querySelectorAll('.folder-link');
        folderLinks.forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                // Folder clicking is managed by the toggle handler above
                // This just prevents default behavior
            });
        });

        // Set up search functionality
        const searchInput = document.getElementById('search-input');
        searchInput.addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase();

            const allFiles = document.querySelectorAll('.file');
            const allDirs = document.querySelectorAll('.directory');

            // Reset visibility
            allFiles.forEach(f => f.style.display = '');
            allDirs.forEach(d => {
                d.style.display = '';
                d.classList.add('expanded');
            });

            if (searchTerm.trim() === '') return;

            // Hide non-matching files
            allFiles.forEach(file => {
                const fileName = file.querySelector('.file-name').textContent.toLowerCase();
                if (!fileName.includes(searchTerm)) {
                    file.style.display = 'none';
                }
            });

            // Hide empty directories
            allDirs.forEach(dir => {
                const hasVisibleChildren = [...dir.querySelectorAll('li')].some(
                    child => child.style.display !== 'none'
                );
                if (!hasVisibleChildren && !dir.querySelector('.folder').textContent.toLowerCase().includes(searchTerm)) {
                    dir.style.display = 'none';
                }
            });
        });
    });
</script>
"@

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EdTech UniverseID Repository Structure</title>
    $css
    <base href="/">
</head>
<body>
    <div class="container">
        <h1>EdTech UniverseID Project Structure</h1>

        <div class="search-container">
            <input type="text" id="search-input" class="search-input" placeholder="Search files and folders...">
        </div>

"@

    foreach ($folder in $INCLUDE_FOLDERS) {
        $path = Join-Path $basePath $folder
        if (Test-Path $path -PathType Container) {
            $html += "    <h2><a href='/$folder' class='folder-link'>$folder/</a></h2>`n"
            $html += "    <div class='directory-content'>`n"
            $html += Get-TreeHtml -basePath $path -relativePath $folder
            $html += "    </div>`n`n"
        }
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $html += @"
        <div class="timestamp">
            Generated on $timestamp
            <br>
            <a href="https://github.com/teknologi-pendidikan/edtech-universeid" class="repo-link">View on GitHub</a>
        </div>
    </div>
    $js
</body>
</html>
"@

    return $html
}

# Generate the directory structure in HTML
$outputDir = "."
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$outputPath = Join-Path $outputDir "directory.html"
$directoryHtml = Get-DirectoryStructureHtml
Set-Content -Path $outputPath -Value $directoryHtml -Encoding UTF8

# Output the path to the created file for confirmation
Write-Host "HTML directory structure created at: $(Resolve-Path $outputPath)" -ForegroundColor Green
Write-Host "This file can now be used with relative paths in any hosting environment." -ForegroundColor Cyan
