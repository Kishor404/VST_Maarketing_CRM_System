import '../styles/customer.css';
import { FaUsers } from "react-icons/fa";
import axios from 'axios';
import Cookies from 'js-cookie';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const BASEURL = "http://157.173.220.208";

const Customer = () => {
    const [searchMode, setSearchMode] = useState("name"); // default search by name
    const [searchQuery, setSearchQuery] = useState("");
    const [customerList, setCustomerList] = useState([]);
    const [filteredList, setFilteredList] = useState([]);
    const [isCreating, setIsCreating] = useState(false);
    const [fetchData, setFetchData] = useState(null);
    const [newCustomer, setNewCustomer] = useState({
        name: "",
        phone: "+91",
        address: "",
        city: "",
        postal_code: "",
        region: Cookies.get("region") || "",
        role: "customer",
        password: "",
    });


    const refreshToken = Cookies.get('refresh_token');
    const headRegion = Cookies.get('region');

    /* ------------------------------------------------------------------ */
    /* ───────────────────────────  ROUTING  ──────────────────────────── */
    /* ------------------------------------------------------------------ */
    const navigate = useNavigate();

    /** Redirect unauthenticated users to /head/ immediately. */
    useEffect(() => {
        const isLoggedIn = Cookies.get('Login') === 'True';
        if (!isLoggedIn) navigate('/head/');
    }, [navigate]);


     const refresh_token = async () => {
        const rToken = Cookies.get('refresh_token');

        try {
            const res = await axios.post(BASEURL+'/api/auth/token/refresh/', 
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
        const getAllCustomers = async () => {
            const AT = await refresh_token();
            if (!AT) return;

            try {
            const res = await axios.get(
                BASEURL+"/api/auth/admin/users/?role=customer",
                {
                headers: { Authorization: `Bearer ${AT}` },
                }
            );

            const regionFiltered = res.data.filter(
                (u) => u.region === headRegion
            );

            setCustomerList(regionFiltered);
            setFilteredList(regionFiltered);
            } catch (err) {
            console.error("Failed to load customers", err);
            }
        };

        getAllCustomers();
    }, []);


    // Filter function for the search
    useEffect(() => {
        if (!searchQuery.trim()) {
            setFilteredList(customerList);
            return;
        }

        const filtered = customerList.filter((customer) => {
            const fieldValue = (customer[searchMode] || "").toString().toLowerCase();
            return fieldValue.includes(searchQuery.toLowerCase());
        });

        setFilteredList(filtered);
    }, [searchQuery, searchMode, customerList]);

    const updateCustomer = async () => {
        if (!fetchData) {
            alert("No customer selected");
            return;
        }
        if(fetchData.name==""){
            alert("Enter Customer Name");
            return;
        }
        if(fetchData.phone.length!=13){
            alert("Enter 10 Digit Phone Number of Customer");
            return;
        }
        if(fetchData.address==""){
            alert("Enter Customer Address");
            return;
        }
        if(fetchData.city==""){
            alert("Enter Customer City");
            return;
        }
        if(fetchData.postal_code==""){
            alert("Enter Customer Postal Code");
            return;
        }

        const AT = await refresh_token();
        if (!AT) return;

        const confirmEdit = window.confirm("Are you sure you want to update the customer ?");
        if (!confirmEdit) {
            alert("Update Cancelled");
            return;
        }

        try {
            await axios.patch(
            BASEURL+`/api/auth/admin/users/${fetchData.id}/update/`,
            fetchData,
            {
                headers: {
                Authorization: `Bearer ${AT}`,
                "Content-Type": "application/json",
                },
            }
            );

            alert("Customer updated successfully");
        } catch (err) {
            console.error(err);
            alert("Failed to update customer");
        }
    };

    const isValidPassword = (password) =>
        password.length >= 8 &&
        /[A-Za-z]/.test(password) &&
        /\d/.test(password);
        
    const createCustomer = async () => {
        
        if(newCustomer.name==""){
            alert("Enter Customer Name");
            return;
        }
        if(newCustomer.phone.length!=13){
            alert("Enter 10 Digit Phone Number of Customer");
            return;
        }
        if(newCustomer.address==""){
            alert("Enter Customer Address");
            return;
        }
        if(newCustomer.city==""){
            alert("Enter Customer City");
            return;
        }
        if(newCustomer.postal_code==""){
            alert("Enter Customer Postal Code");
            return;
        }
        if (!isValidPassword(newCustomer.password)) {
            alert("Password must be at least 8 characters And Contain both Numbers and Letters !");
            return;
        }
        
        
        

        const AT = await refresh_token();
        if (!AT) return;

        const confirmEdit = window.confirm("Are you sure you want to Create the customer ?");
        if (!confirmEdit) {
            alert("Create Cancelled");
            return;
        }

        try {
            await axios.post(
            BASEURL+"/api/auth/admin/users/create/",
            newCustomer,
            {
                headers: {
                Authorization: `Bearer ${AT}`,
                "Content-Type": "application/json",
                },
            }
            );

            alert("Customer created successfully");

            setNewCustomer({
            name: "",
            phone: "+91",
            address: "",
            city: "",
            postal_code: "",
            region: headRegion,
            role: "customer",
            password: "",
            });

            setIsCreating(false);
        } catch (err) {
            console.error(err);
            alert(err?.response?.data?.detail || "Failed to create customer");
        }
    };

    const deleteCustomer = async () => {
        if (!fetchData) {
            alert("No customer selected");
            return;
        }

        const confirmDelete = window.confirm(
            `Are you sure you want to delete customer "${fetchData.name}" ?`
        );

        if (!confirmDelete) {
            alert("Delete Cancelled");
            return;
        }

        const AT = await refresh_token();
        if (!AT) return;

        try {
            await axios.delete(
                BASEURL + `/api/auth/admin/users/delete/${fetchData.id}/`,
                {
                    headers: {
                        Authorization: `Bearer ${AT}`,
                    },
                }
            );

            alert("Customer deleted successfully");

            // Remove deleted customer from UI
            const updatedList = customerList.filter(
                (c) => c.id !== fetchData.id
            );

            setCustomerList(updatedList);
            setFilteredList(updatedList);
            setFetchData(null);
        } catch (err) {
            console.error(err);
            alert("Failed to delete customer");
        }
    };



    // When clicking a row, show details on right panel
    const selectCustomer = (customer) => {
        setFetchData(customer);
        setIsCreating(false);
    };

    // Show all customers and reset search
    const handleShowAll = () => {
        setFilteredList(customerList);
        setSearchQuery("");
        setIsCreating(false);
        setFetchData(null);
    };

    return (

            <div className="customer-cont">
                {/* CUSTOMER LEFT */}
                <div className="customer-left">
                    {/* Search dropdown, input, and buttons in one row */}
                    <div style={{ display: "flex", marginBottom: "10px", gap: "10px", alignItems: "center" }} className='customer-search-bar'>
                        <select
                            value={searchMode}
                            onChange={(e) => setSearchMode(e.target.value)}
                            className="customer-search-mode"
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
                            className="customer-name-search-input"
                        />

                        <button
                            className="customer-edit-button"
                            onClick={() => {
                                setIsCreating(true);
                                setFetchData(null);
                            }}
                        >
                            Add
                        </button>

                        <button
                            className="customer-edit-button"
                            onClick={handleShowAll}
                        >
                            Show All
                        </button>
                    </div>

                    {/* CUSTOMER LIST */}
                    <div className="customer-list-cont">
                        <table className="customer-list" style={{ width: "100%" }}>
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
                                            No customers found.
                                        </td>
                                    </tr>
                                ) : (
                                    filteredList.map((customer) => (
                                        <tr
                                            key={customer.id}
                                            style={{ cursor: "pointer" }}
                                            onClick={() => selectCustomer(customer)}
                                            className={fetchData?.id === customer.id ? "selected-row" : ""}
                                        >
                                            <td>{customer.id}</td>
                                            <td>{customer.name}</td>
                                            <td>{customer.phone}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* CUSTOMER RIGHT */}
                <div className="customer-right">
                    <div className="customer-count-cont">
                        <div className="customer-count-box">
                            <p className="customer-count-value">{filteredList.length}</p>
                            <p className="customer-count-title">Customers</p>
                        </div>
                        <FaUsers className="customer-count-icon" size={50} color="green" />
                    </div>
                    <div className="customer-details-cont">
                        <p className="customer-details-title">
                            {isCreating ? "Add New Customer" : fetchData ? "Customer Details" : "No Customer Selected"}
                        </p>
                        <div className="customer-details-box-cont">
                            {isCreating ? (
                                <>
                                    <DetailBox label="Name" value={newCustomer.name} field="name" setFetchData={setNewCustomer} />

                                    <div className="customer-details-box">
                                    <p className="customer-details-key">Phone</p>
                                    <PhoneInput
                                        value={newCustomer.phone}
                                        onChange={(val) =>
                                        setNewCustomer((prev) => ({ ...prev, phone: val }))
                                        }
                                    />
                                    </div>

                                    <DetailBox label="Address" value={newCustomer.address} field="address" setFetchData={setNewCustomer} />
                                    <DetailBox label="City" value={newCustomer.city} field="city" setFetchData={setNewCustomer} />
                                    <DetailBox label="Postal Code" value={newCustomer.postal_code} field="postal_code" setFetchData={setNewCustomer} />
                                    <DetailBox label="Password" value={newCustomer.password} field="password" setFetchData={setNewCustomer} />

                                </>
                            ) : fetchData ? (
                                <>
                                    <DetailBox label="Name" value={fetchData.name} field="name" setFetchData={setFetchData} />
                                    <div className="customer-details-box">
                                        <p className="customer-details-key">Phone</p>
                                        <PhoneInput
                                            value={fetchData.phone}
                                            onChange={(val) =>
                                            setFetchData((prev) => ({ ...prev, phone: val }))
                                            }
                                        />
                                    </div>

                                    <div className="customer-details-box">
                                    <p className="customer-details-key">Region</p>
                                    <select
                                        className="customer-details-value"
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
                                <p style={{ padding: "20px" }}>Select a customer to view/edit details.</p>
                            )}.
                        </div>
                        {isCreating ? (
                            <button className="customer-details-but" onClick={createCustomer}>
                                Add Customer
                            </button>
                        ) : (
                            fetchData && (
                                <div style={{ display: "flex", gap: "10px" }}>
                                    <button
                                        className="customer-details-but"
                                        onClick={updateCustomer}
                                    >
                                        Update
                                    </button>

                                    <button
                                        className="customer-details-but"
                                        style={{ backgroundColor: "#d9534f" }}
                                        onClick={deleteCustomer}
                                    >
                                        Delete
                                    </button>
                                </div>
                            )
                        )}

                    </div>
                </div>
            </div>
    );
};

// DetailBox Component
const DetailBox = ({ label, value, field, setFetchData }) => (
    <div className="customer-details-box">
        <p className="customer-details-key">{label}</p>
        <input
            className="customer-details-value"
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

export default Customer;

const PhoneInput = ({ value, onChange }) => {
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
