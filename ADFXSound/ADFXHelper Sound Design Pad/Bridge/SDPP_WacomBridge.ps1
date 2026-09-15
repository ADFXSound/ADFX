# Sound Design Paint Pad v0.4.6 - Windows Pen Bridge
# Receives native Windows WM_POINTER pen packets from a nearly invisible overlay
# positioned over the REAPER Paint Pad. Writes normalized telemetry to %TEMP%.
# Hidden-window friendly: PID + heartbeat files let the pad detect a live process
# even when the pen is idle.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$code = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class SDPPPenOverlay : Form
{
    const int WM_POINTERUPDATE = 0x0245;
    const int WM_POINTERDOWN   = 0x0246;
    const int WM_POINTERUP     = 0x0247;
    const uint PT_PEN = 3;

    const uint POINTER_FLAG_INRANGE      = 0x00000002;
    const uint POINTER_FLAG_INCONTACT    = 0x00000004;
    const uint POINTER_FLAG_FIRSTBUTTON  = 0x00000010;
    const uint POINTER_FLAG_SECONDBUTTON = 0x00000020;

    const uint PEN_FLAG_BARREL   = 0x00000001;
    const uint PEN_FLAG_INVERTED = 0x00000002;
    const uint PEN_FLAG_ERASER   = 0x00000004;

    const uint PEN_MASK_PRESSURE = 0x00000001;
    const uint PEN_MASK_TILT_X   = 0x00000004;
    const uint PEN_MASK_TILT_Y   = 0x00000008;

    const int WS_EX_TOOLWINDOW  = 0x00000080;
    const int WS_EX_NOACTIVATE  = 0x08000000;

    const int SM_DIGITIZER = 94;
    const int NID_INTEGRATED_PEN = 0x04;
    const int NID_EXTERNAL_PEN = 0x08;

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINTER_INFO {
        public uint pointerType;
        public uint pointerId;
        public uint frameId;
        public uint pointerFlags;
        public IntPtr sourceDevice;
        public IntPtr hwndTarget;
        public POINT ptPixelLocation;
        public POINT ptHimetricLocation;
        public POINT ptPixelLocationRaw;
        public POINT ptHimetricLocationRaw;
        public uint dwTime;
        public uint historyCount;
        public int InputData;
        public uint dwKeyStates;
        public ulong PerformanceCount;
        public uint ButtonChangeType;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINTER_PEN_INFO {
        public POINTER_INFO pointerInfo;
        public uint penFlags;
        public uint penMask;
        public uint pressure;
        public uint rotation;
        public int tiltX;
        public int tiltY;
    }

    [DllImport("user32.dll", SetLastError=true)]
    static extern bool GetPointerPenInfo(uint pointerId, out POINTER_PEN_INFO penInfo);

    [DllImport("user32.dll", SetLastError=true)]
    static extern bool RegisterPointerInputTarget(IntPtr hwnd, uint pointerType);

    [DllImport("user32.dll")]
    static extern bool SetProcessDPIAware();

    [DllImport("user32.dll")]
    static extern int GetSystemMetrics(int nIndex);

    string temp = Path.GetTempPath();
    string statePath;
    string rectPath;
    string stopPath;
    string pidPath;
    string infoPath;
    string heartbeatPath;
    long seq = 0;
    long heartbeat = 0;
    double lastX = 0.5;
    double lastY = 0.5;
    double lastPressure = 0.0;
    double lastTiltX = 0.0;
    double lastTiltY = 0.0;
    int lastTip = 0;
    int lastB1 = 0;
    int lastB2 = 0;
    int lastEraser = 0;
    Timer rectTimer;
    DateTime ignoreStopUntil;

    public SDPPPenOverlay()
    {
        SetProcessDPIAware();

        statePath     = Path.Combine(temp, "SDPP_WacomBridge_state.txt");
        rectPath      = Path.Combine(temp, "SDPP_WacomBridge_rect.txt");
        stopPath      = Path.Combine(temp, "SDPP_WacomBridge_stop.txt");
        pidPath       = Path.Combine(temp, "SDPP_WacomBridge_pid.txt");
        infoPath      = Path.Combine(temp, "SDPP_WacomBridge_info.txt");
        heartbeatPath = Path.Combine(temp, "SDPP_WacomBridge_heartbeat.txt");
        try { if (File.Exists(stopPath)) File.Delete(stopPath); } catch { }
        // Reloading the REAPER script can fire the previous instance's atexit
        // stop file after this process has already started.
        ignoreStopUntil = DateTime.UtcNow.AddSeconds(1.5);

        WritePid();
        WritePenInfo();
        WriteHeartbeat(false);

        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        StartPosition = FormStartPosition.Manual;

        // Nearly invisible rather than fully transparent so Windows continues
        // to hit-test the overlay for pointer input.
        BackColor = Color.Black;
        Opacity = 0.01;

        Width = 1;
        Height = 1;

        rectTimer = new Timer();
        rectTimer.Interval = 25;
        rectTimer.Tick += (s,e) => {
            CheckStopRequest();
            UpdateRect();
            WriteHeartbeat(false);
        };
        rectTimer.Start();
    }

    protected override CreateParams CreateParams {
        get {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
            return cp;
        }
    }

    protected override bool ShowWithoutActivation { get { return true; } }

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        RegisterPointerInputTarget(this.Handle, PT_PEN);
    }

    protected override void OnFormClosed(FormClosedEventArgs e)
    {
        CleanupFiles();
        base.OnFormClosed(e);
    }

    static uint PointerIdFromWParam(IntPtr wParam)
    {
        long v = wParam.ToInt64();
        return (uint)(v & 0xFFFF);
    }

    static bool ProbePenDevice()
    {
        int digitizer = GetSystemMetrics(SM_DIGITIZER);
        return (digitizer & (NID_INTEGRATED_PEN | NID_EXTERNAL_PEN)) != 0;
    }

    void WritePid()
    {
        try {
            File.WriteAllText(pidPath, Process.GetCurrentProcess().Id.ToString());
        } catch { }
    }

    void WritePenInfo()
    {
        try {
            File.WriteAllText(infoPath, ProbePenDevice() ? "pen=1" : "pen=0");
        } catch { }
    }

    void WriteHeartbeat(bool bumpSeq)
    {
        if (bumpSeq) seq++;
        heartbeat++;

        string line = String.Format(System.Globalization.CultureInfo.InvariantCulture,
            "{0},{1:F6},{2:F6},{3:F6},{4:F6},{5:F6},{6},{7},{8},{9},{10}",
            seq, lastX, lastY, lastPressure, lastTiltX, lastTiltY,
            lastTip, lastB1, lastB2, lastEraser, heartbeat);

        try { File.WriteAllText(statePath, line); } catch { }
        try { File.WriteAllText(heartbeatPath, heartbeat.ToString()); } catch { }
    }

    void CleanupFiles()
    {
        try { if (File.Exists(pidPath)) File.Delete(pidPath); } catch { }
        try { if (File.Exists(heartbeatPath)) File.Delete(heartbeatPath); } catch { }
    }

    void CheckStopRequest()
    {
        try {
            if (DateTime.UtcNow < ignoreStopUntil) return;
            if (File.Exists(stopPath)) {
                File.Delete(stopPath);
                if (rectTimer != null) rectTimer.Stop();
                CleanupFiles();
                this.Close();
                Application.ExitThread();
            }
        } catch { }
    }

    void UpdateRect()
    {
        try {
            if (!File.Exists(rectPath)) return;
            string txt = File.ReadAllText(rectPath).Trim();
            string[] p = txt.Split(',');
            if (p.Length < 5) return;

            int x, y, w, h, active;
            if (!Int32.TryParse(p[0], out x)) return;
            if (!Int32.TryParse(p[1], out y)) return;
            if (!Int32.TryParse(p[2], out w)) return;
            if (!Int32.TryParse(p[3], out h)) return;
            if (!Int32.TryParse(p[4], out active)) return;

            if (active == 0) {
                if (Visible) Hide();
                return;
            }

            w = Math.Max(1, w);
            h = Math.Max(1, h);

            if (!Visible) Show();
            if (Left != x || Top != y || Width != w || Height != h) {
                Bounds = new Rectangle(x, y, w, h);
            }
        } catch { }
    }

    void WritePen(POINTER_PEN_INFO pi)
    {
        Rectangle b = this.Bounds;
        if (b.Width <= 1 || b.Height <= 1) return;

        double x = (pi.pointerInfo.ptPixelLocation.X - b.Left) / (double)b.Width;
        double y = (pi.pointerInfo.ptPixelLocation.Y - b.Top)  / (double)b.Height;
        x = Math.Max(0.0, Math.Min(1.0, x));
        y = Math.Max(0.0, Math.Min(1.0, y));

        double pressure = 0.0;
        if ((pi.penMask & PEN_MASK_PRESSURE) != 0)
            pressure = Math.Max(0.0, Math.Min(1.0, pi.pressure / 1024.0));

        double tx = 0.0;
        double ty = 0.0;
        if ((pi.penMask & PEN_MASK_TILT_X) != 0)
            tx = Math.Max(-1.0, Math.Min(1.0, pi.tiltX / 90.0));
        if ((pi.penMask & PEN_MASK_TILT_Y) != 0)
            ty = Math.Max(-1.0, Math.Min(1.0, pi.tiltY / 90.0));

        bool tip = (pi.pointerInfo.pointerFlags & POINTER_FLAG_INCONTACT) != 0;

        // IMPORTANT:
        // POINTER_FLAG_FIRSTBUTTON can be asserted by the pen TIP/contact on
        // some Windows/Wacom configurations. v0.4 incorrectly treated it as
        // barrel button 1, which meant pressing the pen automatically froze X.
        //
        // PEN_FLAG_BARREL is the pen-specific indication for the primary
        // barrel switch, so use that by itself for B1.
        bool b1 = (pi.penFlags & PEN_FLAG_BARREL) != 0;

        // A secondary barrel switch may be reported as the second pointer
        // button by the Windows pointer stack. Crucially, this does not use
        // FIRSTBUTTON, so normal tip pressure does not engage an axis lock.
        bool b2 = (pi.pointerInfo.pointerFlags & POINTER_FLAG_SECONDBUTTON) != 0;

        bool eraser = ((pi.penFlags & PEN_FLAG_ERASER) != 0) ||
                      ((pi.penFlags & PEN_FLAG_INVERTED) != 0);

        lastX = x;
        lastY = y;
        lastPressure = pressure;
        lastTiltX = tx;
        lastTiltY = ty;
        lastTip = tip ? 1 : 0;
        lastB1 = b1 ? 1 : 0;
        lastB2 = b2 ? 1 : 0;
        lastEraser = eraser ? 1 : 0;

        WriteHeartbeat(true);
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_POINTERUPDATE || m.Msg == WM_POINTERDOWN || m.Msg == WM_POINTERUP)
        {
            uint id = PointerIdFromWParam(m.WParam);
            POINTER_PEN_INFO pi;
            if (GetPointerPenInfo(id, out pi))
            {
                WritePen(pi);
                m.Result = IntPtr.Zero;
                return;
            }
        }
        base.WndProc(ref m);
    }
}

public static class SDPPBridgeMain
{
    [STAThread]
    public static void Run()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new SDPPPenOverlay());
    }
}
'@

$dll = Join-Path $env:TEMP "SDPP_WacomBridge_v047.dll"
$loaded = $false
if (Test-Path -LiteralPath $dll) {
    try {
        Add-Type -Path $dll -ErrorAction Stop
        $loaded = $true
    } catch {
        $loaded = $false
    }
}

if (-not $loaded) {
    try {
        Add-Type -TypeDefinition $code `
            -ReferencedAssemblies System.Windows.Forms,System.Drawing `
            -OutputAssembly $dll `
            -OutputType Library `
            -ErrorAction Stop
        $loaded = $true
    } catch {
        $loaded = $false
        if (Test-Path -LiteralPath $dll) {
            try {
                Add-Type -Path $dll -ErrorAction Stop
                $loaded = $true
            } catch {
                $loaded = $false
            }
        }
    }
}

if (-not $loaded) {
    Add-Type -TypeDefinition $code -ReferencedAssemblies System.Windows.Forms,System.Drawing
}

[SDPPBridgeMain]::Run()
