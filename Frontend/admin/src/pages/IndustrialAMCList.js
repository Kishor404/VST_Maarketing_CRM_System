import React, { useEffect, useState } from "react";
import api from "../api/axiosInstance";
import "../styles/industrial_amc_list.css";

const IndustrialAMCList = () => {

  const [amcs, setAmcs] = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [search, setSearch] = useState("");
  const [sort, setSort] = useState("");
  const [filter, setFilter] = useState("all");
  const [selectedAMC, setSelectedAMC] = useState(null);

  /* ---------------- FETCH ---------------- */

  useEffect(() => {
    fetchAMC();
  }, []);

  const fetchAMC = async () => {
    try {
      const res = await api.get("/crm/industrial-amc/");
      setAmcs(res.data);
      setFiltered(res.data);
    } catch (err) {
      console.error(err);
      alert("Failed to load AMC data");
    }
  };

  /* ---------------- FILTER / SEARCH / SORT ---------------- */

  useEffect(() => {
    let data = [...amcs];

    // 🔍 SEARCH
    if (search.trim()) {
      data = data.filter((a) =>
        (a.card_model || "").toLowerCase().includes(search.toLowerCase()) ||
        (a.customer_name || "").toLowerCase().includes(search.toLowerCase())
      );
    }

    // 🎯 FILTER
    if (filter === "spare") {
      data = data.filter((a) => a.is_with_spare);
    } else if (filter === "no_spare") {
      data = data.filter((a) => !a.is_with_spare);
    }

    // 🔃 SORT
    if (sort === "interval") {
      data.sort((a, b) => a.interval_days - b.interval_days);
    } else if (sort === "date") {
      data.sort(
        (a, b) => new Date(a.start_date) - new Date(b.start_date)
      );
    }

    setFiltered(data);

  }, [search, sort, filter, amcs]);

  /* ---------------- UPDATE ---------------- */

  const updateAMC = async () => {
    try {
      await api.patch(`/crm/industrial-amc/${selectedAMC.id}/`, {
        interval_days: selectedAMC.interval_days,
        start_date: selectedAMC.start_date,
        end_date: selectedAMC.end_date,
        is_with_spare: selectedAMC.is_with_spare,
        spares: selectedAMC.spares || [],
      });

      alert("Updated successfully ✅");
      fetchAMC();
      setSelectedAMC(null);

    } catch (err) {
      console.error(err);
      alert("Update failed ❌");
    }
  };

  /* ---------------- UI ---------------- */

  return (
    <div className="amc-list-container">

      <h2 className="amc-list-title">All Industrial AMC</h2>

      {/* 🔥 CONTROLS */}
      <div className="amc-controls">

        <input
          placeholder="Search by customer or model..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        <select value={sort} onChange={(e) => setSort(e.target.value)}>
          <option value="">Sort</option>
          <option value="interval">Interval</option>
          <option value="date">Start Date</option>
        </select>

        <select value={filter} onChange={(e) => setFilter(e.target.value)}>
          <option value="all">All</option>
          <option value="spare">With Spare</option>
          <option value="no_spare">Without Spare</option>
        </select>

        <span className="amc-count">Total: {filtered.length}</span>

      </div>

      {/* 🔥 TABLE */}
      <div className="amc-table-wrapper">
        <table className="amc-table">

          <thead>
            <tr>
                <th>Customer ID</th>
                <th>Customer</th>
                <th>Model</th>
                <th>Interval</th>
                <th>Start</th>
                <th>End</th>
                <th>Spare</th>
            </tr>
            </thead>

          <tbody>
            {filtered.map((a) => (
                <tr key={a.id} onClick={() =>
                  setSelectedAMC({
                    ...a,
                    spares: a.spares || [], // ✅ ensure array
                    newSpare: ""            // temp input
                  })
                }>

                <td>{a.customer_id}</td>

                <td>{a.customer_name || "-"}</td>

                <td>{a.card_model || "-"}</td>

                <td>{a.interval_days}</td>

                <td>{a.start_date}</td>

                <td>{a.end_date}</td>

                <td>
                    <span
                    className={`badge ${
                        a.is_with_spare ? "badge-spare" : "badge-no-spare"
                    }`}
                    >
                    {a.is_with_spare ? "With Spare" : "Without Spare"}
                    </span>
                </td>

                </tr>
            ))}
            </tbody>

        </table>
      </div>

      {/* 🔥 MODAL */}
      {selectedAMC && (
        <div
          className="amc-modal-overlay"
          onClick={() => setSelectedAMC(null)}
        >

          <div
            className="amc-modal"
            onClick={(e) => e.stopPropagation()}
          >

            <h3>Edit AMC</h3>

            <input
              type="number"
              value={selectedAMC.interval_days}
              onChange={(e) =>
                setSelectedAMC({
                  ...selectedAMC,
                  interval_days: Number(e.target.value),
                })
              }
            />

            <input
              type="date"
              value={selectedAMC.start_date}
              onChange={(e) =>
                setSelectedAMC({
                  ...selectedAMC,
                  start_date: e.target.value,
                })
              }
            />

            <input
              type="date"
              value={selectedAMC.end_date}
              onChange={(e) =>
                setSelectedAMC({
                  ...selectedAMC,
                  end_date: e.target.value,
                })
              }
            />

            <label style={{ display: "flex", justifyContent: "center",gap: "8px", marginTop: "10px" }}>
              <input
                type="checkbox"
                style={{width:"20px"}}
                checked={selectedAMC.is_with_spare || false}
                onChange={(e) =>
                  setSelectedAMC({
                    ...selectedAMC,
                    is_with_spare: e.target.checked,
                    spares: e.target.checked ? selectedAMC.spares || [] : [], // ✅ cleanup
                  })
                }
              />
              With Spare
            </label>

            {selectedAMC.is_with_spare && (
              <div style={{ marginTop: "15px" }}>

                <h4>Add Spares</h4>

                {/* Input + Add button */}
                <div style={{ display: "flex", gap: "10px" }}>
                  <input
                    type="text"
                    placeholder="Enter spare name"
                    value={selectedAMC.newSpare || ""}
                    onChange={(e) =>
                      setSelectedAMC({
                        ...selectedAMC,
                        newSpare: e.target.value,
                      })
                    }
                  />

                  <button
                    onClick={() => {
                      if (!selectedAMC.newSpare?.trim()) return;

                      setSelectedAMC({
                        ...selectedAMC,
                        spares: [
                          ...(selectedAMC.spares || []),
                          selectedAMC.newSpare.trim(),
                        ],
                        newSpare: "",
                      });
                    }}
                  >
                    Add
                  </button>
                </div>

                {/* Spare List */}
                <div style={{ marginTop: "10px" }}>
                  {(selectedAMC.spares || []).map((s, index) => (
                    <div
                      key={index}
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        marginBottom: "5px",
                        background: "#f5f5f5",
                        padding: "5px 10px",
                        borderRadius: "5px",
                      }}
                    >
                      <span>{s}</span>

                      <button
                        onClick={() => {
                          const updated = selectedAMC.spares.filter(
                            (_, i) => i !== index
                          );

                          setSelectedAMC({
                            ...selectedAMC,
                            spares: updated,
                          });
                        }}
                        style={{ color: "red", border: "none", background: "none" }}
                      >
                        ❌
                      </button>
                    </div>
                  ))}
                </div>

              </div>
            )}

            <div style={{ marginTop: "15px" }}>
              <button
                className="amc-btn amc-btn-save"
                onClick={updateAMC}
              >
                Save
              </button>

              <button
                className="amc-btn amc-btn-close"
                onClick={() => setSelectedAMC(null)}
              >
                Close
              </button>
            </div>

          </div>
        </div>
      )}
    </div>
  );
};

export default IndustrialAMCList;