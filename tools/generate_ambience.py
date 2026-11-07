from pathlib import Path
import math,struct,wave
R=Path(__file__).resolve().parents[1]
M=R/'assets/ambience';M.mkdir(exist_ok=True);rate=22050;duration=24;count=rate*duration
for name,notes in {'keep':[146.83,174.61,220.0],'archive':[164.81,196.0,246.94],'crypt':[130.81,155.56,196.0]}.items():
 # Whole-cycle oscillators plus periodic envelopes give a continuous 24-second loop.
 freqs=[round(f*duration)/duration for f in notes];data=bytearray()
 for i in range(count):
  t=i/rate;v=0
  for k,f in enumerate(freqs):
   env=.48+.18*math.sin(2*math.pi*t/duration+k*2.1)
   v+=env*(math.sin(2*math.pi*f*t)+.22*math.sin(2*math.pi*2*f*t))/4
  # Quiet high bell pulses, four evenly spaced notes, with periodic phase.
  phase=(t%(duration/4))/(duration/4);bell=math.sin(math.pi*phase)**8
  v+=.1*bell*math.sin(2*math.pi*freqs[2]*4*t)
  data.extend(struct.pack('<h',int(max(-1,min(1,v*.42))*32767)))
 with wave.open(str(M/f'{name}.wav'),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(data)
