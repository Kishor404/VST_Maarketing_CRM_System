
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/staff.css';
import { FaUsers } from "react-icons/fa";
import axios from 'axios';
import Cookies from 'js-cookie';

const Staff = () => {
    /* ------------------------------------------------------------------ */
        /* ───────────────────────────  ROUTING  ──────────────────────────── */
        /* ------------------------------------------------------------------ */
        const navigate = useNavigate();
    
        /** Redirect unauthenticated users to /head/ immediately. */
        useEffect(() => {
            const isLoggedIn = Cookies.get('Login') === 'True';
            if (!isLoggedIn) navigate('/head/');
        }, [navigate]);
    
    const [searchMode, setSearchMode] = useState("name"); // default search by name
    const [searchQuery, setSearchQuery] = useState("");
    const [staffList, setstaffList] = useState([]);
    const [filteredList, setFilteredList] = useState([]);
    const [isCreating, setIsCreating] = useState(false);
    const [fetchData, setFetchData] = useState(null);
    const [newstaff, setNewstaff] = useState({
        name: "",
        phone: "+91",
        address: "",
        city: "",
        postal_code: "",
        region: Cookies.get("region") || "",
        role: "worker",
        password: "",
    });


    const [changePassword, setChangePassword]=useState(false);
    const [changePasswordPhone, setChangePasswordPhone] = useState("+91");
    const [changePasswordPassword, setChangePasswordPassword]=useState("");

    const refreshToken = Cookies.get('refresh_token');
    const headRegion = Cookies.get('region');

    const isValidPassword = (password) =>
        password.length >= 8 &&
        /[A-Za-z]/.test(password) &&
        /\d/.test(password);


    const refresh_token = async () => {
        const rToken = Cookies.get('refresh_token');

        try {
            const res = await axios.post('http://127.0.0.1:8000/api/auth/token/refresh/', 
                { 'refresh': rToken }, 
                { headers: { "Content-Type": "application/json" } }
            );
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            navigate('/head/');
            return null;
        }
    };


    useEffect(() => {
        const getAllStaffs = async () => {
            const AT = await refresh_token();
            if (!AT) return;

            try {
            const res = await axios.get(
                "http://127.0.0.1:8000/api/auth/admin/users/?role=worker",
                {
                headers: {
                    Authorization: `Bearer ${AT}`,
                },
                }
            );

            // Optional frontend region filter
            const regionFiltered = res.data.filter(
                (u) => u.region === headRegion
            );

            setstaffList(regionFiltered);
            setFilteredList(regionFiltered);
            } catch (err) {
            console.error("Failed to load staffs", err);
            }
        };

        getAllStaffs();
    }, []);

    const withCountryCode = (phone) => {
        if (!phone) return "+91";
        if (phone.startsWith("+91")) return phone;
        return `+91${phone}`;
    };



    // Filter function for the search
    useEffect(() => {
        if (!searchQuery.trim()) {
            setFilteredList(staffList);
            return;
        }

        const filtered = staffList.filter((staff) => {
            const fieldValue = (staff[searchMode] || "").toString().toLowerCase();
            return fieldValue.includes(searchQuery.toLowerCase());
        });

        setFilteredList(filtered);
    }, [searchQuery, searchMode, staffList]);

    const updatestaff = async () => {
        if (!fetchData) return alert("No staff selected");
        if(fetchData.name==""){
            alert("Enter staff Name");
            return;
        }
        if(fetchData.phone.length!=13){
            alert("Enter 10 Digit Phone Number of staff");
            return;
        }
        if(fetchData.address==""){
            alert("Enter staff Address");
            return;
        }
        if(fetchData.city==""){
            alert("Enter staff City");
            return;
        }
        if(fetchData.postal_code==""){
            alert("Enter staff Postal Code");
            return;
        }
        const AT = await refresh_token();
        if (!AT) return;

        const payload = {
            ...fetchData,
            phone: withCountryCode(fetchData.phone),
        };

        const confirmEdit = window.confirm("Are you sure you want to update the staff ?");
        if (!confirmEdit) {
            alert("Update Cancelled");
            return;
        }

        try {
            await axios.patch(
            `http://127.0.0.1:8000/api/auth/admin/users/${fetchData.id}/update/`,
            payload,
            {
                headers: {
                Authorization: `Bearer ${AT}`,
                "Content-Type": "application/json",
                },
            }
            );

            alert("Staff updated successfully");
        } catch (err) {
            console.error(err);
            alert("Update failed");
        }
        };

const createstaff = async () => {
    if(newstaff.name==""){
            alert("Enter Staff Name");
            return;
    }
    if(newstaff.phone.length!=13){
        alert("Enter 10 Digit Phone Number of Staff");
        return;
    }
    if(newstaff.address==""){
        alert("Enter Staff Address");
        return;
    }
    if(newstaff.city==""){
        alert("Enter Staff City");
        return;
    }
    if(newstaff.postal_code==""){
        alert("Enter Staff Postal Code");
        return;
    }
    if (!isValidPassword(newstaff.password)) {
        alert(
        "Password must be at least 8 characters long and contain both letters and numbers"
        );
        return;
    }

  const AT = await refresh_token();
  if (!AT) return;

  const payload = {
    ...newstaff,
    phone: newstaff.phone,
  };

  const confirmEdit = window.confirm("Are you sure you want to Create the staff ?");
    if (!confirmEdit) {
        alert("Create Cancelled");
        return;
    }

  try {
    await axios.post(
      "http://127.0.0.1:8000/api/auth/admin/users/create/",
      payload,
      {
        headers: {
          Authorization: `Bearer ${AT}`,
          "Content-Type": "application/json",
        },
      }
    );

    alert("Staff created successfully");

    setIsCreating(false);
    setNewstaff({
      name: "",
      phone: "+91",
      address: "",
      city: "",
      postal_code: "",
      region: headRegion,
      role: "worker",
      password: "",
    });
  } catch (err) {
    console.error(err);
    alert(err?.response?.data?.detail || "Failed to create staff");
  }
};


    // When clicking a row, show details on right panel
    const selectstaff = (staff) => {
        setFetchData({
            ...staff,
            phone: withCountryCode(staff.phone),
        });
        setIsCreating(false);
    };


    // Show all staffs and reset search
    const handleShowAll = () => {
        setFilteredList(staffList);
        setSearchQuery("");
        setIsCreating(false);
        setFetchData(null);
    };

    const OpenChangePassword=()=>{
        setChangePassword(!changePassword);
    }
    const getUserByPhone=async(phone)=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const res = await axios.get(`http://127.0.0.1:8000/api/auth/admin/users/?phone=${phone}`, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("GET USER BY PHONE");
            return res.data[0];
        } catch (error) {
            console.error("Error in Get User By Phone:", error);
            return null;
        }
    }
    const handleChangePassword = async (e) => {
        e.preventDefault();

        if (!isValidPassword(changePasswordPassword)) {
            alert("Password must be at least 8 characters long and contain both letters and numbers");
            return;
        }
        if(changePasswordPhone.length!=10){
            alert("Enter 10 Digit Phone Number");
            return;
        }

        const AT = await refresh_token();
        if (!AT) return;

        const user=await getUserByPhone(changePasswordPhone);
        const confirmEdit = window.confirm("Are you sure you want to update the Password ?");
        if (!confirmEdit) {
            alert("Update Cancelled");
            return;
        }

        try {
            await axios.post(
            `http://127.0.0.1:8000/api/auth/admin/users/${user.id}/change-password/`,
            { new_password: changePasswordPassword },
            {
                headers: {
                Authorization: `Bearer ${AT}`,
                "Content-Type": "application/json",
                },
            }
            );

            alert("Password changed successfully");
            setChangePassword(false);
            setChangePasswordPassword("");
            setChangePasswordPhone("+91");
        } catch (err) {
            console.error(err);
            alert("Password change failed");
        }
    };





    return (

            <div className="staff-cont">

                {changePassword?
                <div className='staff-change-password-dialog'>
                    <a onClick={OpenChangePassword}></a>
                    <form onSubmit={handleChangePassword}>
                        <p>Change Staff Password</p>
                        <div className='staff-change-password-inputs'>

                            <input
                                type="text"
                                placeholder="Enter Phone Number"
                                value={changePasswordPhone}
                                onChange={(e) => setChangePasswordPhone(e.target.value)}
                                required
                            />
                            <input
                                type="text"
                                placeholder="Enter New Password"
                                value={changePasswordPassword}
                                onChange={(e) => setChangePasswordPassword(e.target.value)}
                                required
                            />

                        </div>
                        
                        <button type='submit'>Change Password</button>
                    </form>
                    
                    
                </div>
                :<></>}
                {/* staff LEFT */}
                <div className="staff-left">
                    {/* Search dropdown, input, and buttons in one row */}
                    <div style={{ display: "flex", marginBottom: "10px", gap: "10px", alignItems: "center" }} className='staff-search-bar'>
                        <select
                            value={searchMode}
                            onChange={(e) => setSearchMode(e.target.value)}
                            className="staff-search-mode"
                            style={{ padding: "5px", minWidth: "140px" }}
                        >
                            <option value="name">Search by Name</option>
                            <option value="phone">Search by Phone</option>
                            <option value="id">Search by ID</option>
                        </select>

                        <input
                            type="text"
                            placeholder={`Search by ${searchMode.charAt(0).toUpperCase() + searchMode.slice(1)}`}
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="staff-name-search-input"
                        />

                        <button
                            className="staff-edit-button"
                            onClick={() => {
                                setIsCreating(true);
                                setFetchData(null);
                            }}
                        >
                            Add
                        </button>

                        <button
                            className="staff-edit-button"
                            onClick={handleShowAll}
                        >
                            Show All
                        </button>
                        
                    </div>

                    {/* staff LIST */}
                    <div className="staff-list-cont">
                        <table className="staff-list" style={{ width: "100%" }}>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Name</th>
                                    <th>Phone</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredList.length === 0 ? (
                                    <tr>
                                        <td colSpan={3} style={{ textAlign: "center", padding: "10px" }}>
                                            No staffs found.
                                        </td>
                                    </tr>
                                ) : (
                                    filteredList.map((staff) => (
                                        <tr
                                            key={staff.id}
                                            style={{ cursor: "pointer" }}
                                            onClick={() => selectstaff(staff)}
                                            className={fetchData?.id === staff.id ? "selected-row" : ""}
                                        >
                                            <td>{staff.id}</td>
                                            <td>{staff.name}</td>
                                            <td>{staff.phone}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* staff RIGHT */}
                <div className="staff-right">
                    <div className='staff-right-top-cont'>
                        <button className="staff-right-top-but" onClick={OpenChangePassword}>
                            Change Password
                        </button>
                        <div className="staff-count-cont">
                            <div className="staff-count-box">
                                <p className="staff-count-value">{filteredList.length}</p>
                                <p className="staff-count-title">staffs</p>
                            </div>
                            <FaUsers className="staff-count-icon" size={50} color="green" />
                        </div>
                    </div>
                    <div className="staff-details-cont">
                        <p className="staff-details-title">
                            {isCreating ? "Add New staff" : fetchData ? "staff Details" : "No staff Selected"}
                        </p>
                        <div className="staff-details-box-cont">
                            {isCreating ? (
                                <>
                                    <DetailBox label="Name" value={newstaff.name} field="name" setFetchData={setNewstaff} />

                                    <div className="staff-details-box">
                                    <p className="staff-details-key">Phone</p>
                                    <PhoneInput
                                        value={newstaff.phone}
                                        onChange={(val) =>
                                        setNewstaff((prev) => ({ ...prev, phone: val }))
                                        }
                                    />
                                    </div>

                                    <DetailBox label="Address" value={newstaff.address} field="address" setFetchData={setNewstaff} />
                                    <DetailBox label="City" value={newstaff.city} field="city" setFetchData={setNewstaff} />
                                    <DetailBox label="Postal Code" value={newstaff.postal_code} field="postal_code" setFetchData={setNewstaff} />
                                    <DetailBox label="Password" value={newstaff.password} field="password" setFetchData={setNewstaff} />

                                </>
                            ) : fetchData ? (
                                <>
                                    <DetailBox label="Name" value={fetchData.name} field="name" setFetchData={setFetchData} />
                                    <div className="staff-details-box">
                                        <p className="staff-details-key">Phone</p>
                                        <PhoneInput
                                            value={fetchData.phone}
                                            onChange={(val) =>
                                            setFetchData((prev) => ({ ...prev, phone: val }))
                                            }
                                        />
                                    </div>

                                    <div className="staff-details-box">
                                    <p className="staff-details-key">Region</p>
                                    <select
                                        className="staff-details-value"
                                        value={fetchData.region || ""}
                                        onChange={(e) =>
                                        setFetchData((prev) => ({
                                            ...prev,
                                            region: e.target.value,
                                        }))
                                        }
                                    >
                                        <option value="rajapalayam">Rajapalayam</option>
                                        <option value="ambasamuthiram">Ambasamuthiram</option>
                                        <option value="sankarankovil">Sankarankovil</option>
                                        <option value="tenkasi">Tenkasi</option>
                                        <option value="tirunelveli">Tirunelveli</option>
                                        <option value="chennai">Chennai</option>
                                    </select>
                                    </div>
                                    <DetailBox label="Address" value={fetchData.address} field="address" setFetchData={setFetchData} />
                                    <DetailBox label="City" value={fetchData.city} field="city" setFetchData={setFetchData} />
                                    <DetailBox label="Postal Code" value={fetchData.postal_code} field="postal_code" setFetchData={setFetchData} />
                                    <div className="staff-details-box">
                                        <p className="staff-details-key">Role</p>
                                        <select
                                            className="staff-details-value"
                                            value={fetchData.role}
                                            onChange={(e) =>
                                            setFetchData((prev) => ({
                                                ...prev,
                                                role: e.target.value,
                                            }))
                                            }
                                        >
                                            <option value="customer">Customer</option>
                                            <option value="worker">Worker</option>
                                            <option value="admin">Admin</option>
                                        </select>
                                    </div>

                                </>
                            ) : (
                                <p style={{ padding: "20px" }}>Select a staff to view/edit details.</p>
                            )}
                        </div>
                        {isCreating ? (
                            <button className="staff-details-but" onClick={createstaff}>
                                Add staff
                            </button>
                        ) : (
                            fetchData && (
                                <button className="staff-details-but" onClick={updatestaff}>
                                    Update
                                </button>
                            )
                        )}
                    </div>
                </div>
            </div>
    );
};

// DetailBox Component
const DetailBox = ({ label, value, field, setFetchData }) => (
    <div className="staff-details-box">
        <p className="staff-details-key">{label}</p>
        <input
            className="staff-details-value"
            value={value || ""}
            onChange={(e) =>
                setFetchData((prevVal) =>
                    typeof prevVal === "object"
                        ? { ...prevVal, [field]: e.target.value }
                        : e.target.value
                )
            }
        />
    </div>
);

export default Staff;

const PhoneInput = ({ value, onChange }) => {
  // remove +91 if present
  const localNumber = value?.replace(/^\+91/, "") || "";

  return (
    <div className="phone-input-wrapper">
      <span className="phone-prefix">+91</span>
      <input
        type="text"
        className="phone-input"
        value={localNumber}
        maxLength={10}
        onChange={(e) => {
          const digitsOnly = e.target.value.replace(/\D/g, "");
          onChange(`+91${digitsOnly}`);
        }}
        placeholder="Enter phone number"
      />
    </div>
  );
};
