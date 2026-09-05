<#
.SYNOPSIS
    Shared look and layout for the dialogs in Shared/Inputs.
.DESCRIPTION
    Dot source this file, it only defines helpers and never shows anything by itself. Every dialog is
    built from the same skeleton: a header docked to the top, a footer docked to the bottom holding
    the actions, and a body filling what is left, which is the only part that scrolls. Header and
    footer are docked rather than table rows so they always keep their full height, the body is what
    gives way when the dialog runs out of room.
.EXAMPLE
    . "$PSScriptRoot\Form-Style.ps1";
    $layout = New-InputForm -Title 'Pick' -Message 'Pick one';
    Add-InputFormButton -Layout $layout -Text 'Ok' -DialogResult OK -Accept | Out-Null;
#>

Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;
[System.Windows.Forms.Application]::EnableVisualStyles();

$script:InputFormFont = New-Object System.Drawing.Font("Segoe UI", 10);
$script:InputFormPadding = New-Object System.Windows.Forms.Padding(12, 8, 12, 8);

function New-InputForm {
    <#
    .SYNOPSIS
        Creates the standard dialog shell and returns its Form, Header, Body and Footer.
    #>
    param (
        [string]$Title,
        [string]$Message,
        [int]$MessageWidth = 520
    )

    $form = New-Object System.Windows.Forms.Form;
    $form.Text = $Title;
    $form.StartPosition = 'CenterScreen';
    $form.Font = $script:InputFormFont;
    $form.MinimizeBox = $false;
    $form.MaximizeBox = $false;
    $form.ShowIcon = $false;
    $form.Padding = $script:InputFormPadding;
    $form.BackColor = [System.Drawing.SystemColors]::Window;

    # Body first, then footer, then header: docking is applied in reverse of the order the controls
    # were added, so the header claims the top, the footer the bottom, and the body the remainder.
    $bodyPanel = New-Object System.Windows.Forms.Panel;
    $bodyPanel.Dock = [System.Windows.Forms.DockStyle]::Fill;
    $bodyPanel.AutoScroll = $true;
    $form.Controls.Add($bodyPanel);

    # Footer: actions, filled right to left so the first button added is the rightmost one.
    $footerPanel = New-Object System.Windows.Forms.FlowLayoutPanel;
    $footerPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom;
    $footerPanel.AutoSize = $true;
    $footerPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
    $footerPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft;
    $footerPanel.WrapContents = $false;
    $footerPanel.Padding = New-Object System.Windows.Forms.Padding(0, 8, 0, 0);
    $form.Controls.Add($footerPanel);

    # Header: free content on the left, status on the right.
    $headerPanel = New-Object System.Windows.Forms.TableLayoutPanel;
    $headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top;
    $headerPanel.AutoSize = $true;
    $headerPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
    $headerPanel.ColumnCount = 2;
    $headerPanel.RowCount = 1;
    $headerPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null;
    $headerPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null;
    $form.Controls.Add($headerPanel);

    $messageLabel = $null;
    if ($Message) {
        $messageLabel = New-Object System.Windows.Forms.Label;
        $messageLabel.Text = $Message;
        $messageLabel.AutoSize = $true;
        # Long messages wrap instead of stretching the dialog off screen. Set-InputFormSize narrows
        # this to the width the dialog actually ends up with.
        $messageLabel.MaximumSize = New-Object System.Drawing.Size($MessageWidth, 0);
        $messageLabel.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 8);
        $headerPanel.Controls.Add($messageLabel, 0, 0);
    }

    return [PSCustomObject]@{
        Form         = $form;
        Header       = $headerPanel;
        Body         = $bodyPanel;
        Footer       = $footerPanel;
        MessageLabel = $messageLabel;
    };
}

function Add-InputFormButton {
    <#
    .SYNOPSIS
        Adds a footer action. The first button added sits rightmost.
    #>
    param (
        [Parameter(Mandatory)]$Layout,
        [Parameter(Mandatory)][string]$Text,
        [System.Windows.Forms.DialogResult]$DialogResult = [System.Windows.Forms.DialogResult]::None,
        [switch]$Accept,
        [switch]$Cancel,
        [scriptblock]$OnClick
    )

    $button = New-Object System.Windows.Forms.Button;
    $button.Text = $Text;
    $button.AutoSize = $true;
    $button.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
    $button.MinimumSize = New-Object System.Drawing.Size(110, 32);
    $button.Margin = New-Object System.Windows.Forms.Padding(8, 0, 0, 0);
    $button.DialogResult = $DialogResult;
    $button.UseMnemonic = $false;
    $Layout.Footer.Controls.Add($button);

    if ($Accept) {
        $Layout.Form.AcceptButton = $button;
    }

    if ($Cancel) {
        $Layout.Form.CancelButton = $button;
    }

    if ($OnClick) {
        $button.Add_Click($OnClick);
    }

    return $button;
}

function Get-InputFormBounds {
    <#
    .SYNOPSIS
        How large a dialog may grow on the screen the mouse is currently on.
    #>
    $workingArea = [System.Windows.Forms.Screen]::FromPoint([System.Windows.Forms.Cursor]::Position).WorkingArea;
    $maxFormWidth = [int]($workingArea.Width * 0.9);
    $maxFormHeight = [int]($workingArea.Height * 0.85);
    return [PSCustomObject]@{
        MaxFormWidth  = $maxFormWidth;
        MaxFormHeight = $maxFormHeight;
        # Room left for the body once the window chrome, header and footer take their share.
        MaxBodyWidth  = $maxFormWidth - 60;
        MaxBodyHeight = $maxFormHeight - 140;
    };
}

function Get-InputGridColumnCount {
    <#
    .SYNOPSIS
        Picks how many columns a list of equally sized items should be laid out in.
    .DESCRIPTION
        Short lists stay in one column, longer ones spread out so they can be read without scrolling.
        Past the soft limit only height forces further columns, a very wide grid is hard to scan.
    #>
    param (
        [int]$ItemCount,
        [int]$ItemWidth,
        [int]$ItemHeight,
        [Parameter(Mandatory)]$Bounds,
        [int]$Requested = 0,
        [int]$PreferredRows = 8,
        [int]$SoftColumnLimit = 4
    )

    if ($ItemCount -le 1) {
        return 1;
    }

    if ($Requested -gt 0) {
        return [int][Math]::Max(1, [Math]::Min($Requested, $ItemCount));
    }

    $fitByWidth = [Math]::Max(1, [Math]::Floor($Bounds.MaxBodyWidth / [Math]::Max(1, $ItemWidth)));
    $columnCount = [Math]::Min([Math]::Ceiling($ItemCount / $PreferredRows), $SoftColumnLimit);
    while ((([Math]::Ceiling($ItemCount / $columnCount)) * $ItemHeight) -gt $Bounds.MaxBodyHeight -and $columnCount -lt $fitByWidth) {
        $columnCount++;
    }

    return [int][Math]::Max(1, [Math]::Min([Math]::Min($columnCount, $fitByWidth), $ItemCount));
}

function Set-InputFormSize {
    <#
    .SYNOPSIS
        Sizes the dialog around its content, growing up to the screen bounds.
    .DESCRIPTION
        Width comes from the widest of body, header and footer, so a dialog is never narrower than its
        own message or its own buttons. The height estimate cannot know the exact chrome, so whatever
        is still missing is added once the form has a real layout.
    #>
    param (
        [Parameter(Mandatory)]$Layout,
        [Parameter(Mandatory)]$Bounds,
        # Dialogs whose whole content is a message in the header pass nothing here.
        $Content = $null,
        [int]$MinWidth = 360,
        [int]$MinHeight = 180
    )

    $form = $Layout.Form;
    $contentSize = $Content ? $Content.PreferredSize : (New-Object System.Drawing.Size(0, 0));
    $neededWidth = [Math]::Max($contentSize.Width, [Math]::Max($Layout.Header.PreferredSize.Width, $Layout.Footer.PreferredSize.Width));
    $clientWidth = [int][Math]::Max($MinWidth, [Math]::Min($Bounds.MaxBodyWidth, $neededWidth) + $form.Padding.Horizontal);

    # Wrap the message at the width the dialog really gets, otherwise the header is measured against
    # one width and painted at another, and the difference comes out of the buttons.
    $labelWidth = $clientWidth - $form.Padding.Horizontal - ($Layout.MessageLabel ? $Layout.MessageLabel.Margin.Horizontal : 0);
    if ($Layout.MessageLabel) {
        $Layout.MessageLabel.MaximumSize = New-Object System.Drawing.Size($labelWidth, 0);
    }

    # Everything is measured against the window the screen can actually hold.
    $maxClientHeight = $Bounds.MaxFormHeight - 40;
    $bodyHeight = [Math]::Min($Bounds.MaxBodyHeight, $contentSize.Height);
    $headerHeight = $Layout.Header.PreferredSize.Height;
    $maxHeaderHeight = $maxClientHeight - $bodyHeight - $Layout.Footer.PreferredSize.Height - $form.Padding.Vertical;
    if ($headerHeight -gt $maxHeaderHeight) {
        # A message taller than the screen scrolls inside the header, the actions have to stay
        # reachable. Re-wrap it narrower first, so the scrollbar does not cost it a column of text.
        if ($Layout.MessageLabel) {
            $narrowed = $labelWidth - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth;
            $Layout.MessageLabel.MaximumSize = New-Object System.Drawing.Size($narrowed, 0);
        }

        $Layout.Header.AutoSize = $false;
        $Layout.Header.AutoScroll = $true;
        $Layout.Header.Height = [int][Math]::Max(60, $maxHeaderHeight);
        $headerHeight = $Layout.Header.Height;
    }

    $clientHeight = $bodyHeight + $headerHeight + $Layout.Footer.PreferredSize.Height + $form.Padding.Vertical;
    $clientHeight = [Math]::Min($clientHeight, $maxClientHeight);

    $form.MinimumSize = New-Object System.Drawing.Size($MinWidth, $MinHeight);
    $form.ClientSize = New-Object System.Drawing.Size($clientWidth, [int][Math]::Max($clientHeight, $MinHeight - 40));

    # GetNewClosure keeps these locals alive for the handler, it runs long after this function returns.
    $form.Add_Shown({
            $needed = $Layout.Header.Height + $Layout.Footer.Height + $form.Padding.Vertical `
                + ($Content ? [Math]::Min($Bounds.MaxBodyHeight, $Content.PreferredSize.Height) : 0);
            $missingHeight = $needed - $form.ClientSize.Height;
            if ($missingHeight -gt 0) {
                $form.Height += [Math]::Max(0, [Math]::Min($missingHeight, $Bounds.MaxFormHeight - $form.Height));
            }

            if ($Content) {
                $missingWidth = $Content.PreferredSize.Width - $Layout.Body.ClientSize.Width;
                if ($missingWidth -gt 0) {
                    $form.Width += [Math]::Max(0, [Math]::Min($missingWidth, $Bounds.MaxFormWidth - $form.Width));
                }
            }
        }.GetNewClosure());
}
