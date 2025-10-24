// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title WeatherOracle
 * @notice Weather data for solar/wind production forecasting and insurance
 * @dev Supports historical data and staleness checks
 */
contract WeatherOracle is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    struct WeatherData {
        uint16 temperature;    // Celsius * 10 (e.g., 250 = 25.0°C)
        uint16 windSpeed;      // m/s * 10
        uint16 solarIrradiance;// W/m² (0-1500)
        uint8 cloudCover;      // 0-100%
        uint64 timestamp;      // Unix timestamp
    }
    
    // Location hash => timestamp => weather data
    mapping(bytes32 => mapping(uint64 => WeatherData)) public historicalData;
    
    // Location hash => latest weather data
    mapping(bytes32 => WeatherData) public currentWeather;
    
    uint64 public heartbeat = 1 hours; // Max staleness
    
    event WeatherUpdated(
        bytes32 indexed location,
        uint16 temperature,
        uint16 windSpeed,
        uint16 solarIrradiance,
        uint8 cloudCover,
        uint64 timestamp
    );
    event HeartbeatUpdated(uint64 newHeartbeat);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }
    
    /**
     * @notice Update weather data for location
     * @param location Location identifier (e.g., keccak256("lat:42.36,lon:-71.06"))
     * @param temperature Celsius * 10
     * @param windSpeed m/s * 10
     * @param solarIrradiance W/m² (0-1500)
     * @param cloudCover 0-100%
     * @param timestamp Unix timestamp of reading
     */
    function updateWeather(
        bytes32 location,
        uint16 temperature,
        uint16 windSpeed,
        uint16 solarIrradiance,
        uint8 cloudCover,
        uint64 timestamp
    ) external onlyRole(ORACLE_ROLE) {
        require(cloudCover <= 100, "Invalid cloud cover");
        require(solarIrradiance <= 1500, "Invalid irradiance");
        require(timestamp <= block.timestamp, "Future timestamp");
        
        WeatherData memory data = WeatherData({
            temperature: temperature,
            windSpeed: windSpeed,
            solarIrradiance: solarIrradiance,
            cloudCover: cloudCover,
            timestamp: timestamp
        });
        
        // Store in historical data
        historicalData[location][timestamp] = data;
        
        // Update current weather if newer
        if (timestamp > currentWeather[location].timestamp) {
            currentWeather[location] = data;
        }
        
        emit WeatherUpdated(location, temperature, windSpeed, solarIrradiance, cloudCover, timestamp);
    }
    
    /**
     * @notice Batch update weather data
     * @param locations Array of location identifiers
     * @param temperatures Array of temperatures (Celsius * 10)
     * @param windSpeeds Array of wind speeds (m/s * 10)
     * @param solarIrradiances Array of irradiances (W/m²)
     * @param cloudCovers Array of cloud covers (0-100%)
     * @param timestamp Unix timestamp for all readings
     */
    function batchUpdate(
        bytes32[] calldata locations,
        uint16[] calldata temperatures,
        uint16[] calldata windSpeeds,
        uint16[] calldata solarIrradiances,
        uint8[] calldata cloudCovers,
        uint64 timestamp
    ) external onlyRole(ORACLE_ROLE) {
        require(
            locations.length == temperatures.length &&
            locations.length == windSpeeds.length &&
            locations.length == solarIrradiances.length &&
            locations.length == cloudCovers.length,
            "Array length mismatch"
        );
        require(timestamp <= block.timestamp, "Future timestamp");
        
        for (uint256 i = 0; i < locations.length; i++) {
            require(cloudCovers[i] <= 100, "Invalid cloud cover");
            require(solarIrradiances[i] <= 1500, "Invalid irradiance");
            
            WeatherData memory data = WeatherData({
                temperature: temperatures[i],
                windSpeed: windSpeeds[i],
                solarIrradiance: solarIrradiances[i],
                cloudCover: cloudCovers[i],
                timestamp: timestamp
            });
            
            historicalData[locations[i]][timestamp] = data;
            
            if (timestamp > currentWeather[locations[i]].timestamp) {
                currentWeather[locations[i]] = data;
            }
            
            emit WeatherUpdated(
                locations[i],
                temperatures[i],
                windSpeeds[i],
                solarIrradiances[i],
                cloudCovers[i],
                timestamp
            );
        }
    }
    
    /**
     * @notice Get current weather (reverts if stale)
     * @param location Location identifier
     * @return Weather data
     */
    function getCurrentWeather(bytes32 location) external view returns (WeatherData memory) {
        WeatherData memory data = currentWeather[location];
        require(data.timestamp > 0, "No data");
        require(block.timestamp - data.timestamp <= heartbeat, "Data stale");
        return data;
    }
    
    /**
     * @notice Get historical weather data
     * @param location Location identifier
     * @param timestamp Unix timestamp
     * @return Weather data
     */
    function getHistoricalWeather(bytes32 location, uint64 timestamp)
        external
        view
        returns (WeatherData memory)
    {
        WeatherData memory data = historicalData[location][timestamp];
        require(data.timestamp > 0, "No data");
        return data;
    }
    
    /**
     * @notice Try get current weather (returns empty if stale)
     * @param location Location identifier
     * @return data Weather data (timestamp=0 if unavailable)
     */
    function tryGetCurrentWeather(bytes32 location) external view returns (WeatherData memory data) {
        data = currentWeather[location];
        
        if (data.timestamp == 0) {
            return data; // No data
        }
        
        if (block.timestamp - data.timestamp > heartbeat) {
            return WeatherData(0, 0, 0, 0, 0); // Stale data
        }
        
        return data;
    }
    
    /**
     * @notice Set heartbeat (max staleness)
     * @param newHeartbeat New heartbeat in seconds
     */
    function setHeartbeat(uint64 newHeartbeat) external onlyRole(ADMIN_ROLE) {
        require(newHeartbeat > 0, "Invalid heartbeat");
        heartbeat = newHeartbeat;
        emit HeartbeatUpdated(newHeartbeat);
    }
}
