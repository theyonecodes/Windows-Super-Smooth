#!/usr/bin/env python3
"""
Windows Super Smooth GUI - Dark theme tkinter interface
Uses theyonecodes-toolkit DarkTheme for consistent styling.
"""

import sys
import os
import subprocess
import threading
import json
from pathlib import Path

# Add toolkit to path
toolkit_path = Path(__file__).parent / "vendor" / "toolkit"
if toolkit_path.exists():
    sys.path.insert(0, str(toolkit_path))

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
from datetime import datetime

# Import DarkTheme from toolkit
try:
    from toolkit.gui.dark_theme import (
        apply_dark_theme, create_dark_button, create_dark_frame,
        create_dark_label, create_dark_combobox, create_dark_treeview,
        create_dark_progressbar, create_dark_separator,
        BG, BG2, BG3, FG, FG2, ACCENT, GREEN, RED, AMBER, GRAY,
        BORDER, FONT, FONT_BOLD, FONT_TITLE, FONT_MONO,
        STATUS_COLORS
    )
    HAS_TOOLKIT = True
except ImportError:
    HAS_TOOLKIT = False
    # Fallback colors
    BG = "#0D1117"
    BG2 = "#161B22"
    BG3 = "#1C2128"
    FG = "#E6EDF3"
    FG2 = "#8B949E"
    ACCENT = "#58A6FF"
    GREEN = "#3FB950"
    RED = "#F85149"
    AMBER = "#D29922"
    GRAY = "#8B949E"
    BORDER = "#30363D"
    FONT = ("Segoe UI", 10)
    FONT_BOLD = ("Segoe UI", 10, "bold")
    FONT_TITLE = ("Segoe UI", 16, "bold")
    FONT_MONO = ("Consolas", 10)
    STATUS_COLORS = {"PASS": GREEN, "FAIL": RED, "WARNING": AMBER, "PENDING": GRAY}


class WindowsSuperSmoothGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Windows Super Smooth")
        self.root.minsize(1000, 700)
        self.root.configure(bg=BG)
        self.root.state("zoomed")
        
        self.ps_script = Path(__file__).parent / "WindowsSuperSmooth.ps1"
        self.log_path = Path.home() / "Downloads" / "systemcare.log"
        self.running_task = None
        
        self._build_ui()
        self._load_initial_info()
    
    def _build_ui(self):
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(3, weight=1)
        
        # ========== ROW 0: Header ==========
        header = tk.Frame(self.root, bg=BG2, height=56, highlightthickness=0)
        header.grid(row=0, column=0, sticky="ew")
        header.grid_propagate(False)
        
        tk.Label(header, text="WINDOWS SUPER SMOOTH", bg=BG2, fg=ACCENT,
                 font=FONT_TITLE).pack(side=tk.LEFT, padx=25, pady=14)
        
        # Status indicators
        status_frame = tk.Frame(header, bg=BG2)
        status_frame.pack(side=tk.RIGHT, padx=25, pady=14)
        
        self.backup_status = tk.Label(status_frame, text="BACKUP: ON" if HAS_TOOLKIT else "BACKUP: OFF",
                                      bg=BG2, fg=GREEN if HAS_TOOLKIT else AMBER,
                                      font=FONT_MONO)
        self.backup_status.pack(side=tk.LEFT, padx=(0, 12))
        
        self.admin_status = tk.Label(status_frame, text="ADMIN: YES" if self._is_admin() else "ADMIN: NO",
                                     bg=BG2, fg=GREEN if self._is_admin() else RED,
                                     font=FONT_MONO)
        self.admin_status.pack(side=tk.LEFT)
        
        # ========== ROW 1: Toolbar ==========
        toolbar = tk.Frame(self.root, bg=BG, highlightthickness=0)
        toolbar.grid(row=1, column=0, sticky="ew", padx=20, pady=(16, 4))
        toolbar.columnconfigure(1, weight=1)
        
        # Category selector
        cat_frame = tk.Frame(toolbar, bg=BG3, highlightthickness=1, highlightbackground=BORDER)
        cat_frame.grid(row=0, column=0, sticky="w", padx=(0, 8))
        cat_frame.columnconfigure(1, weight=1)
        
        tk.Label(cat_frame, text="Category:", bg=BG3, fg=FG2, font=FONT).grid(row=0, column=0, padx=(8, 4))
        self.category_var = tk.StringVar(value="All")
        self.category_combo = create_dark_combobox(cat_frame, 
            values=["All", "Performance", "Gaming", "Privacy", "Maintenance", "Debloat"],
            textvariable=self.category_var, state="readonly", width=15)
        self.category_combo.grid(row=0, column=1, padx=(4, 8), pady=4)
        self.category_combo.bind("<<ComboboxSelected>>", lambda e: self._filter_tasks())
        
        # Right side - Jev triage button
        if HAS_TOOLKIT:
            jej_btn = create_dark_button(toolbar, "JEV TRIAGE", self._run_jev_triage, variant="warn")
            jej_btn.grid(row=0, column=2, padx=(8, 0), sticky="e")
        
        # ========== ROW 2: Task List ==========
        list_frame = tk.Frame(self.root, bg=BG2, highlightthickness=1, highlightbackground=BORDER)
        list_frame.grid(row=2, column=0, sticky="nsew", padx=20, pady=(8, 4))
        list_frame.columnconfigure(0, weight=1)
        list_frame.rowconfigure(0, weight=1)
        
        # Task treeview
        columns = ("name", "category", "description", "risk")
        self.tree = create_dark_treeview(list_frame, columns=columns, show="headings")
        
        self.tree.heading("name", text="Task", anchor="w")
        self.tree.heading("category", text="Category", anchor="center")
        self.tree.heading("description", text="Description", anchor="w")
        self.tree.heading("risk", text="Risk", anchor="center")
        
        self.tree.column("name", width=200, minwidth=150)
        self.tree.column("category", width=120, minwidth=100)
        self.tree.column("description", width=450, minwidth=300)
        self.tree.column("risk", width=80, minwidth=60)
        
        # Scrollbars
        vscroll = ttk.Scrollbar(list_frame, orient="vertical", command=self.tree.yview,
                                style="Dark.Vertical.TScrollbar")
        hscroll = ttk.Scrollbar(list_frame, orient="horizontal", command=self.tree.xview,
                                style="Dark.Horizontal.TScrollbar")
        self.tree.configure(yscrollcommand=vscroll.set, xscrollcommand=hscroll.set)
        
        self.tree.grid(row=0, column=0, sticky="nsew", padx=(4, 0), pady=4)
        vscroll.grid(row=0, column=1, sticky="ns", pady=4)
        hscroll.grid(row=1, column=0, sticky="ew", padx=4)
        
        # Bind selection
        self.tree.bind("<<TreeviewSelect>>", self._on_select)
        self.tree.bind("<Double-1>", lambda e: self._run_selected())
        
        # Populate tasks
        self._all_tasks = self._get_tasks()
        self._populate_tree(self._all_tasks)
        
        # ========== ROW 3: Action Bar & Log ==========
        bottom = tk.Frame(self.root, bg=BG)
        bottom.grid(row=3, column=0, sticky="ew", padx=20, pady=(4, 16))
        bottom.columnconfigure(0, weight=1)
        bottom.rowconfigure(1, weight=1)
        
        # Action buttons
        action_frame = tk.Frame(bottom, bg=BG)
        action_frame.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        
        self.run_btn = create_dark_button(action_frame, "RUN SELECTED", self._run_selected, variant="accent")
        self.run_btn.pack(side=tk.LEFT, padx=(0, 8))
        
        self.run_all_btn = create_dark_button(action_frame, "RUN ALL VISIBLE", self._run_all_visible, variant="warn")
        self.run_all_btn.pack(side=tk.LEFT, padx=(0, 8))
        
        self.turbo_btn = create_dark_button(action_frame, "TURBO MODE", self._run_turbo, variant="danger")
        self.turbo_btn.pack(side=tk.LEFT, padx=(0, 8))
        
        self.clear_log_btn = create_dark_button(action_frame, "CLEAR LOG", self._clear_log, variant="ghost")
        self.clear_log_btn.pack(side=tk.RIGHT)
        
        # Progress bar
        self.progress_var = tk.DoubleVar()
        self.progress = create_dark_progressbar(bottom, variable=self.progress_var, maximum=100)
        self.progress.grid(row=1, column=0, sticky="ew", pady=(0, 8))
        
        # Log area
        log_frame = tk.Frame(bottom, bg=BG2, highlightthickness=1, highlightbackground=BORDER)
        log_frame.grid(row=2, column=0, sticky="nsew")
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        
        self.log_text = scrolledtext.ScrolledText(
            log_frame, bg=BG, fg=FG, font=FONT_MONO,
            insertbackground=FG, selectbackground=ACCENT, selectforeground="#FFFFFF",
            highlightthickness=0, bd=0, wrap=tk.WORD
        )
        self.log_text.grid(row=0, column=0, sticky="nsew", padx=4, pady=4)
        self.log_text.configure(state=tk.DISABLED)
        
        # Context menu
        self._create_context_menu()
    
    def _create_context_menu(self):
        self.context_menu = tk.Menu(self.root, tearoff=0, bg=BG2, fg=FG,
                                    activebackground=ACCENT, activeforeground="#FFFFFF",
                                    font=FONT)
        self.context_menu.add_command(label="Run", command=self._run_selected)
        self.context_menu.add_command(label="Show PowerShell Command", command=self._show_ps_command)
        self.context_menu.add_separator()
        self.context_menu.add_command(label="View Backup Info", command=self._view_backup_info)
        
        def show_context(event):
            item = self.tree.identify_row(event.y)
            if item:
                self.tree.selection_set(item)
                self.context_menu.post(event.x_root, event.y_root)
        
        self.tree.bind("<Button-3>", show_context)
    
    def _is_admin(self):
        try:
            import ctypes
            return ctypes.windll.shell32.IsUserAnAdmin() != 0
        except:
            return False
    
    def _get_tasks(self):
        """Define all available tasks with metadata."""
        return [
            # Performance Tweaks
            {"id": "disable_services", "name": "Disable Unneeded Services",
             "category": "Performance", "description": "Disable telemetry, Xbox, print spooler, etc.",
             "risk": "LOW", "func": "Invoke-PerformanceTweaks -ServicesOnly",
             "registry_keys": ["HKLM:\\SYSTEM\\CurrentControlSet\\Services\\DiagTrack",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\XblAuthManager",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\WMPNetworkSvc"]},
            
            {"id": "disable_scheduled_tasks", "name": "Disable Telemetry Tasks",
             "category": "Performance", "description": "Disable scheduled defrag, CEIP, maps updates",
             "risk": "LOW", "func": "Invoke-PerformanceTweaks -TasksOnly",
             "file_paths": ["C:\\Windows\\System32\\Tasks\\Microsoft\\Windows\\DiskCleanup",
                           "C:\\Windows\\System32\\Tasks\\Microsoft\\Windows\\Defrag"]},
            
            {"id": "registry_perf", "name": "Registry Performance Tweaks",
             "category": "Performance", "description": "TCP, filesystem, memory, priority tweaks",
             "risk": "MEDIUM", "func": "Invoke-PerformanceTweaks -RegistryOnly",
             "registry_keys": ["HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\PriorityControl"]},
            
            {"id": "gpu_priority", "name": "GPU Priority (External NVIDIA)",
             "category": "Performance", "description": "Force high-performance GPU, NVIDIA max power",
             "risk": "MEDIUM", "func": "Invoke-PerformanceTweaks -GPUOnly",
             "registry_keys": ["HKCU:\\SOFTWARE\\Microsoft\\DirectX\\UserGpuPreferences",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\GraphicsDrivers"]},
            
            {"id": "power_plan", "name": "High Performance Power Plan",
             "category": "Performance", "description": "Set ultimate performance, disable timeouts",
             "risk": "LOW", "func": "Invoke-PerformanceTweaks -PowerOnly",
             "backup_bcd": True},
            
            {"id": "network_tcp", "name": "TCP Stack Optimization",
             "category": "Performance", "description": "Auto-tuning, chimney, DCA, RSS, timestamps",
             "risk": "LOW", "func": "Invoke-PerformanceTweaks -NetworkOnly"},
            
            # Gaming Mode
            {"id": "gaming_mode", "name": "Gaming Mode (Full)",
             "category": "Gaming", "description": "Kill hogs, MMCSS, GameDVR off, NVIDIA max, priority",
             "risk": "MEDIUM", "func": "Invoke-GamingMode",
             "registry_keys": ["HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
                              "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\GameDVR",
                              "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR"]},
            
            # Privacy
            {"id": "disable_telemetry", "name": "Disable Telemetry",
             "category": "Privacy", "description": "Stop DiagTrack, dmwappushservice, allowtelemetry=0",
             "risk": "LOW", "func": "Invoke-PrivacyTweaks -TelemetryOnly",
             "registry_keys": ["HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\DiagTrack",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\dmwappushservice"]},
            
            {"id": "disable_location", "name": "Disable Location Tracking",
             "category": "Privacy", "description": "Disable lfsvc, location policies",
             "risk": "LOW", "func": "Invoke-PrivacyTweaks -LocationOnly",
             "registry_keys": ["HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\LocationAndSensors",
                              "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\lfsvc"]},
            
            {"id": "disable_ads_tips", "name": "Disable Ads & Tips",
             "category": "Privacy", "description": "ContentDeliveryManager, advertising ID, suggestions",
             "risk": "LOW", "func": "Invoke-PrivacyTweaks -AdsOnly",
             "registry_keys": ["HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
                              "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AdvertisingInfo"]},
            
            # Maintenance
            {"id": "clean_temp", "name": "Deep Temp Cleanup",
             "category": "Maintenance", "description": "Clean %TEMP%, Windows Temp, Prefetch, thumbnails",
             "risk": "LOW", "func": "Invoke-Maintenance -TempOnly",
             "file_paths": [os.environ.get("TEMP", ""), "C:\\Windows\\Temp", "C:\\Windows\\Prefetch",
                           os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft\\Windows\\Explorer")]},
            
            {"id": "reset_wu", "name": "Reset Windows Update Cache",
             "category": "Maintenance", "description": "Clear SoftwareDistribution, restart wuauserv",
             "risk": "LOW", "func": "Invoke-Maintenance -WUOnly",
             "file_paths": ["C:\\Windows\\SoftwareDistribution\\Download"]},
            
            {"id": "clear_logs", "name": "Clear Event Logs",
             "category": "Maintenance", "description": "Clear all Windows event logs",
             "risk": "MEDIUM", "func": "Invoke-Maintenance -LogsOnly"},
            
            {"id": "rebuild_icon", "name": "Rebuild Icon Cache",
             "category": "Maintenance", "description": "Restart explorer, delete IconCache.db",
             "risk": "LOW", "func": "Invoke-Maintenance -IconsOnly"},
            
            # Debloat
            {"id": "debloat", "name": "Remove Bloatware",
             "category": "Debloat", "description": "Remove pre-installed apps (Candy Crush, Spotify, etc.)",
             "risk": "LOW", "func": "Invoke-Debloat"},
            
            # Turbo Mode
            {"id": "turbo", "name": "TURBO MODE (ALL)",
             "category": "All", "description": "One-click: power, visual, GameBar, services, GPU, temp, hogs",
             "risk": "HIGH", "func": "Invoke-TurboMode",
             "registry_keys": ["HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects",
                              "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\GameDVR",
                              "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications",
                              "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR",
                              "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeliveryOptimization"]},
        ]
    
    def _populate_tree(self, tasks):
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        for i, task in enumerate(tasks):
            risk_color = {"LOW": GREEN, "MEDIUM": AMBER, "HIGH": RED}.get(task["risk"], FG2)
            item_id = self.tree.insert("", "end", values=(
                task["name"], task["category"], task["description"], task["risk"]
            ), tags=(f"risk_{task['risk'].lower()}", task["id"]))
            
            # Alternate row colors
            if i % 2 == 0:
                self.tree.item(item_id, tags=(f"risk_{task['risk'].lower()}", task["id"], "even"))
        
        # Configure tags
        self.tree.tag_configure("risk_low", foreground=GREEN)
        self.tree.tag_configure("risk_medium", foreground=AMBER)
        self.tree.tag_configure("risk_high", foreground=RED)
        self.tree.tag_configure("even", background=BG3)
    
    def _filter_tasks(self):
        cat = self.category_var.get()
        if cat == "All":
            filtered = self._all_tasks
        else:
            filtered = [t for t in self._all_tasks if t["category"] == cat]
        self._populate_tree(filtered)
    
    def _on_select(self, event):
        selection = self.tree.selection()
        if selection:
            item = self.tree.item(selection[0])
            task_id = item["tags"][1] if len(item["tags"]) > 1 else None
            if task_id:
                task = next((t for t in self._all_tasks if t["id"] == task_id), None)
                if task:
                    self._log(f"Selected: {task['name']} [{task['category']}] Risk: {task['risk']}")
                    if task.get("registry_keys"):
                        self._log(f"  Registry keys affected: {len(task['registry_keys'])}")
                    if task.get("file_paths"):
                        self._log(f"  File paths affected: {len(task['file_paths'])}")
                    if task.get("backup_bcd"):
                        self._log("  ⚠ Will backup BCD before changes")
    
    def _run_selected(self):
        selection = self.tree.selection()
        if not selection:
            messagebox.showwarning("No Selection", "Please select a task first")
            return
        
        item = self.tree.item(selection[0])
        task_id = item["tags"][1] if len(item["tags"]) > 1 else None
        if task_id:
            self._run_task(task_id)
    
    def _run_all_visible(self):
        items = self.tree.get_children()
        if not items:
            return
        
        if not messagebox.askyesno("Run All", f"Run all {len(items)} visible tasks? This may take several minutes."):
            return
        
        for item_id in items:
            item = self.tree.item(item_id)
            task_id = item["tags"][1] if len(item["tags"]) > 1 else None
            if task_id:
                self._run_task(task_id, wait=True)
    
    def _run_turbo(self):
        if not messagebox.askyesno("Turbo Mode", 
            "Turbo Mode applies ALL optimizations in one click.\n"
            "This includes: power plan, visual effects, GameDVR, services, GPU, temp cleanup, process killing.\n\n"
            "A full system backup will be created first (registry, BCD, services).\n\n"
            "Continue?"):
            return
        self._run_task("turbo", wait=True)
    
    def _run_task(self, task_id, wait=False):
        task = next((t for t in self._all_tasks if t["id"] == task_id), None)
        if not task:
            return
        
        self.run_btn.configure(state=tk.DISABLED)
        self.run_all_btn.configure(state=tk.DISABLED)
        self.turbo_btn.configure(state=tk.DISABLED)
        self.progress_var.set(0)
        
        def worker():
            try:
                self._log(f"=== Starting: {task['name']} ===")
                self._log(f"Category: {task['category']} | Risk: {task['risk']}")
                
                # Build PowerShell command
                ps_cmd = self._build_ps_command(task)
                
                self._log(f"Command: {ps_cmd[:200]}...")
                
                # Execute
                proc = subprocess.Popen(
                    ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps_cmd],
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, bufsize=1, creationflags=subprocess.CREATE_NO_WINDOW
                )
                
                # Stream output
                for line in proc.stdout:
                    line = line.rstrip()
                    if line:
                        self._log(line)
                        # Update progress based on output
                        if "Applied" in line and "optimizations" in line:
                            self.progress_var.set(100)
                
                proc.wait()
                
                if proc.returncode == 0:
                    self._log(f"=== COMPLETED: {task['name']} ===")
                    if HAS_TOOLKIT:
                        self._log("Backup created successfully")
                else:
                    self._log(f"=== FAILED (exit code {proc.returncode}) ===")
                
            except Exception as e:
                self._log(f"ERROR: {str(e)}")
            finally:
                self.root.after(0, self._reset_buttons)
        
        threading.Thread(target=worker, daemon=True).start()
    
    def _build_ps_command(self, task):
        """Build PowerShell command to run a specific function."""
        func = task["func"]
        
        # Add toolkit path
        toolkit_ps = self.ps_script.parent / "vendor" / "toolkit" / "backup-engine" / "powershell" / "BackupEngine.psm1"
        
        cmd_parts = [
            f"$ErrorActionPreference = 'Stop'",
            f"Import-Module '{toolkit_ps}' -Force -ErrorAction SilentlyContinue",
            f". '{self.ps_script}'",
            f"{func}"
        ]
        
        # Add parameters for targeted runs
        if "Only" in func and not func.startswith("Invoke-"):
            pass  # The function handles its own parameters
        
        return "; ".join(cmd_parts)
    
    def _run_jev_triage(self):
        if not HAS_TOOLKIT:
            messagebox.showwarning("Jev Router", "Toolkit not available")
            return
        
        self._log("=== JEV TRIAGE ===")
        
        def worker():
            try:
                router_path = toolkit_path / "jev-router" / "jev_router.py"
                if not router_path.exists():
                    self._log("Jev Router not found")
                    return
                
                context = {
                    "task_type": "system_optimization",
                    "sensitive": True,
                    "required_capabilities": ["system_admin", "registry", "services", "bcd"]
                }
                
                result = subprocess.run(
                    [sys.executable, str(router_path), "--choice", "system_optimization", 
                     "--context", json.dumps(context)],
                    capture_output=True, text=True, timeout=30
                )
                
                if result.returncode == 0:
                    decision = json.loads(result.stdout)
                    self._log(f"Model: {decision.get('model_name', 'N/A')}")
                    self._log(f"Confidence: {decision.get('confidence', 0)*100:.0f}%")
                    self._log(f"Reasoning: {decision.get('reasoning', 'N/A')}")
                    if decision.get('requires_human'):
                        self._log("⚠ HUMAN REVIEW REQUIRED", level="warn")
                    if decision.get('triggered_guardrails'):
                        self._log(f"Guardrails: {', '.join(decision['triggered_guardrails'])}")
                else:
                    self._log(f"Jev Router error: {result.stderr}")
            except Exception as e:
                self._log(f"Jev error: {e}")
        
        threading.Thread(target=worker, daemon=True).start()
    
    def _show_ps_command(self):
        selection = self.tree.selection()
        if not selection:
            return
        item = self.tree.item(selection[0])
        task_id = item["tags"][1] if len(item["tags"]) > 1 else None
        if task_id:
            task = next((t for t in self._all_tasks if t["id"] == task_id), None)
            if task:
                cmd = self._build_ps_command(task)
                # Show in dialog
                dialog = tk.Toplevel(self.root)
                dialog.title(f"PowerShell Command: {task['name']}")
                dialog.geometry("800x500")
                dialog.configure(bg=BG)
                dialog.transient(self.root)
                
                txt = scrolledtext.ScrolledText(dialog, bg=BG, fg=FG, font=FONT_MONO,
                                               insertbackground=FG, wrap=tk.WORD)
                txt.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
                txt.insert(tk.END, cmd)
                txt.configure(state=tk.DISABLED)
    
    def _view_backup_info(self):
        if not HAS_TOOLKIT:
            messagebox.showinfo("Backup Info", "Toolkit not loaded - no backup info available")
            return
        
        backup_root = Path.home() / "ToolBackups"
        if backup_root.exists():
            backups = sorted(backup_root.glob("*"), key=lambda p: p.stat().st_mtime, reverse=True)[:10]
            msg = "Recent backups:\n\n"
            for b in backups:
                manifest = b / "MANIFEST.csv"
                if manifest.exists():
                    lines = manifest.read_text().strip().split('\n')
                    msg += f"{b.name}: {len(lines)-1} items\n"
                else:
                    msg += f"{b.name}: (no manifest)\n"
        else:
            msg = "No backups found"
        messagebox.showinfo("Backup History", msg)
    
    def _log(self, message, level="info"):
        self.root.after(0, lambda: self._append_log(message, level))
    
    def _append_log(self, message, level="info"):
        self.log_text.configure(state=tk.NORMAL)
        timestamp = datetime.now().strftime("%H:%M:%S")
        color_map = {"info": FG, "warn": AMBER, "error": RED, "ok": GREEN}
        color = color_map.get(level, FG)
        
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)
        
        # Also write to file
        try:
            with open(self.log_path, "a", encoding="utf-8") as f:
                f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | {message}\n")
        except:
            pass
    
    def _clear_log(self):
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.configure(state=tk.DISABLED)
    
    def _reset_buttons(self):
        self.run_btn.configure(state=tk.NORMAL)
        self.run_all_btn.configure(state=tk.NORMAL)
        self.turbo_btn.configure(state=tk.NORMAL)
        self.progress_var.set(0)
    
    def _load_initial_info(self):
        self._log("Windows Super Smooth GUI started")
        self._log(f"Backup Engine: {'Available' if HAS_TOOLKIT else 'NOT AVAILABLE'}")
        self._log(f"Admin Rights: {'YES' if self._is_admin() else 'NO'}")
        self._log(f"Toolkit Path: {toolkit_path}")
        
        # Load system info
        def worker():
            try:
                # Quick system info
                cpu = subprocess.run(["wmic", "cpu", "get", "Name", "/value"], 
                                   capture_output=True, text=True, timeout=5)
                if cpu.returncode == 0:
                    for line in cpu.stdout.split('\n'):
                        if line.startswith("Name="):
                            self._log(f"CPU: {line[5:].strip()}")
                            break
                
                mem = subprocess.run(["wmic", "os", "get", "TotalVisibleMemorySize,FreePhysicalMemory", "/value"],
                                   capture_output=True, text=True, timeout=5)
                if mem.returncode == 0:
                    total = free = 0
                    for line in mem.stdout.split('\n'):
                        if line.startswith("TotalVisibleMemorySize="):
                            total = int(line.split("=")[1])
                        elif line.startswith("FreePhysicalMemory="):
                            free = int(line.split("=")[1])
                    if total:
                        used = (total - free) / 1024
                        total_gb = total / 1024
                        self._log(f"RAM: {used:.1f} / {total_gb:.1f} GB ({used/total_gb*100:.0f}%)")
            except:
                pass
        
        threading.Thread(target=worker, daemon=True).start()


def main():
    root = tk.Tk()
    
    # Apply dark theme if toolkit available
    if HAS_TOOLKIT:
        apply_dark_theme(root)
    else:
        root.configure(bg=BG)
        # Configure basic ttk styles
        style = ttk.Style(root)
        style.theme_use("clam")
        style.configure("Treeview", background=BG2, foreground=FG, fieldbackground=BG2,
                       borderwidth=0, font=FONT, rowheight=28)
        style.map("Treeview", background=[("selected", ACCENT)], foreground=[("selected", "#FFFFFF")])
        style.configure("Treeview.Heading", background=BG3, foreground=FG, font=FONT_BOLD,
                       borderwidth=1, relief="flat")
    
    app = WindowsSuperSmoothGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()