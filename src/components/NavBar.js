import React from "react";
import Connect from "./Connect";
import logo from "../assets/images/swiftstay.png";

import "../assets/css/Home.css";
import {useNavigate} from "react-router-dom";

function NavBar() {
    let navigate = useNavigate();
    return (<div className="topBanner">
        <div>
            <img className="logo" src={logo} alt="logo"></img>
        </div>
        <div className="tabs">
            <div className="selected">Places To Stay</div>
            <div onClick={() => navigate('/add-rental')}>
                Add Property
            </div>
            <div onClick={() => navigate('/dashboard')}>
                Dashboard
            </div>
        </div>
        <div className="lrContainers">
            <Connect/>
        </div>
    </div>);
}

export default NavBar;
