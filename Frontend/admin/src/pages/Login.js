import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import "../styles/Login.css";
import Logo from "../assets/logo.jpg";
import "../styles/fonts.css";
import Cookies from "js-cookie";

const BASEURL = "http://157.173.220.208";

const Login = () => {
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const formattedPhone = phone.startsWith("+91")
    ? phone
    : `+91${phone}`;


  const handleSubmit = async (e) => {
    e.preventDefault();

    const formattedPhone = phone.startsWith("+91")? phone:`+91${phone}`;

    try {
      const response = await fetch(
        BASEURL+"/api/auth/login/",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            phone: formattedPhone,
            password,
          }),
        }
      );

      if (!response.ok) {
        throw new Error("Invalid phone or password");
      }

      const data = await response.json();
      console.log("Login Response:", data);

      const { access, refresh, user } = data;

      // 🔐 Role check (adjust if needed)
      if (user.role !== "admin") {
        alert("Invalid role for admin panel");
        Cookies.set("Login", "False", { expires: 7 });
        return;
      }

      // ✅ Store tokens & user info
      Cookies.set("access_token", access, { expires: 1 });
      Cookies.set("refresh_token", refresh, { expires: 7 });

      Cookies.set("Login", "True", { expires: 7 });
      Cookies.set("user_id", user.id, { expires: 7 });
      Cookies.set("name", user.name, { expires: 7 });
      Cookies.set("phone", user.phone, { expires: 7 });
      Cookies.set("role", user.role, { expires: 7 });
      Cookies.set("region", user.region ?? "", { expires: 7 });

      alert("Login Successful");

      // 🚀 Redirect
      if (user.role === "admin") {
        navigate("/head/service");
      }

    } catch (error) {
      console.error(error);
      alert(error.message);
      Cookies.set("Login", "False", { expires: 7 });
    }
  };

  return (
    <div className="Login-main">
      <div className="Login-box">
        <img src={Logo} alt="Logo" width="70%" />
        <p className="Login-heading">Admin Login</p>

        <form onSubmit={handleSubmit} className="Login-form">
        <div className="Login-input-phone">
          <input className="Login-input-phonecode" value={"+91"} disabled/>
          <input
            className="Login-input-number"
            type="tel"
            placeholder="Phone"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            required
          />
        </div>
          

          <input
            className="Login-input"
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          <button type="submit" className="Login-button">
            Login
          </button>
        </form>
      </div>
    </div>
  );
};

export default Login;
