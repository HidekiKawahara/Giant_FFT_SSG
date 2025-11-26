# **Getting Started: Acoustic Checker by GFFT**

## **Overview**

**Acoustic Checker by GFFT** is an interactive MATLAB application designed for acoustic system measurement. It allows users to analyze system impulse responses, separate LTI (Linear Time-Invariant) components from RTV (Time-Variant/Noise) components, and visualize power decay characteristics in real-time.

## **Prerequisites**

* **MATLAB:** Installed with App Designer support.  
* **Audio Hardware:** A full-duplex audio interface (ASIO for Windows or CoreAudio for macOS is recommended).  
* **Test Signal:** A cyclic audio file (WAV/AIF) to be used as the source stimulus (e.g., TSP, Pink Noise).

## **Step-by-Step Guide**

### **1\. Initial Setup**

When the application launches, most controls will be disabled (grayed out) to ensure the correct setup sequence.

1. **Set Working Folder:**  
   * Click the **"Set working folder"** button in the center panel.  
   * Select a directory on your computer.  
   * The app will create a new subfolder (e.g., acTest2023...) to store all snapshots, recordings, and log files.  
   * *Note: Audio settings will remain locked until this folder is set.*

### **2\. Audio Configuration**

Configure your audio hardware in the **Left Panel**. These steps must be done in order:

1. **IO Device Selection:** Select your audio interface from the dropdown. The app filters for devices supporting full-duplex (simultaneous recording and playback).  
2. **Sampling Frequency:** Once the device is selected, choose a supported sample rate (e.g., 48000 Hz).  
3. **Input Channels:** Select the number of input channels (1 or 2).

### **3\. Loading the Test Signal**

Before measuring, you must load the cyclic stimulus signal.

1. Click the **"Load cyclic data"** button.  
2. Select your stimulus file (.wav or .aif).  
3. **Note:** If the file's sampling rate does not match your selected hardware rate, the app will attempt to update the settings or ask you to select a different file.

### **4\. Running the Measurement**

Once the signal is loaded, the **START** button will become active.

1. **Start Streaming:** Click **START**. The application will begin playing the stimulus and recording the response.  
2. **Real-Time Analysis:** The graphs on the right will update continuously.  
3. **Stop:** Click **STOP** to end the measurement.  
   * *Auto-Save:* Source and captured audio files are automatically saved to your working folder upon stopping.

## **Understanding the Displays (Right Panel)**

The application provides three main visualizations:

### **1\. Spectrum Display (Top Chart)**

Shows the frequency response of the system.

* **Blue Line (LTI):** The Linear Time-Invariant gain (The "clean" impulse response).  
* **Red Line (RTV):** The Random Time-Variant gain (Distortion or background noise).  
* **Controls:** You can switch between **Raw DFT**, **1/6 Octave**, and **1/12 Octave** smoothing using the radio buttons on the left.

### **2\. Band SPL (Bottom Left Chart)**

Displays the Sound Pressure Level.

* **Blue Line:** Current Signal Level.  
* **Green Line (Snapshot):** A frozen reference curve. Click **"Snapshot Level"** to update the green reference line with the current data.

### **3\. Power Response (Bottom Right Chart)**

Shows the energy decay over time (Impulse Response envelope).

* **Green Line:** Energy at 1 kHz.  
* **Blue Line:** Energy at the frequency selected by the slider.  
* **Slider:** Use the **BPF fc** slider to change the frequency band being analyzed in this view.

## **Additional Features**

### **Calibration**

To ensure accurate SPL readings:

1. Ensure streaming is **Stopped**.  
2. Click **Calibrate** (Ch1 or Ch2).  
3. The system will generate a calibration tone.  
4. Input the measured dB value from your reference SPL meter into the dropdown or allow the system to calculate based on input sensitivity.

### **Voice Memo**

* Click **"Voice memo 5s"** to record a quick 5-second audio note (e.g., describing the test setup). This is saved to the working folder.

### **GUI Snapshot**

* Click **"snapshot GUI"** to save an image (.png) of the current interface and graphs to the working folder.