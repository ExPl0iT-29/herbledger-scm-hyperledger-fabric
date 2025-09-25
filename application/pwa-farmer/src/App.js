import React, { useState } from 'react';

function App() {
  const [gps, setGps] = useState('');
  const [species, setSpecies] = useState('');
  const [batchId, setBatchId] = useState('');

  const captureHarvest = async () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((pos) => {
        const gps = `${pos.coords.latitude},${pos.coords.longitude}`;
        setGps(gps);
        // TODO: Offline queue with IndexedDB, sync to Fabric
        console.log(`Batch ${batchId}: ${species} at ${gps}`);
        // SMS fallback (stub)
        // fetch('https://sms-gateway-api', { method: 'POST', body: JSON.stringify({ batchId, gps, species }) });
      }, (err) => {
        console.error('GPS error:', err);
        // Trigger SMS fallback
      });
    }
  };

  return (
    <div>
      <h1>HerbLedger Farmer PWA</h1>
      <input placeholder="Batch ID" onChange={(e) => setBatchId(e.target.value)} />
      <input placeholder="Species (e.g., Ashwagandha)" onChange={(e) => setSpecies(e.target.value)} />
      <button onClick={captureHarvest}>Capture Harvest</button>
      <p>GPS: {gps}</p>
    </div>
  );
}

export default App;