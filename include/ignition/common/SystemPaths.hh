/*
 * Copyright (C) 2012-2014 Open Source Robotics Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
*/
#ifndef IGNITION_COMMON_SYSTEMPATHS_HH_
#define IGNITION_COMMON_SYSTEMPATHS_HH_

#include <stdio.h>

#ifdef _WIN32
  #include <direct.h>
  #define GetCurrentDir _getcwd
#else
  #include <unistd.h>
  #define GetCurrentDir getcwd
#endif

#include <string>
#include <memory>
#include <list>
#include <functional>

namespace ignition
{
  namespace common
  {
    // Forward declare private data class
    class SystemPathsPrivate;

    /// \class SystemPaths SystemPaths.hh ignition/common/SystemPaths.hh
    /// \brief Functions to handle getting system paths, keeps track of:
    ///        \li SystemPaths#pluginPaths - plugin library paths
    ///            for common::WorldPlugin
    class SystemPaths
    {
      /// \brief Constructor for SystemPaths
      public: SystemPaths();

      /// \brief Destructor
      public: virtual ~SystemPaths();

      /// \brief Get the log path
      /// \return the path
      public: std::string LogPath() const;

      /// \brief Get the plugin paths
      /// \return a list of paths
      public: const std::list<std::string> &PluginPaths();

      /// \brief Find a file or path using a URI
      /// \param[in] _uri the uniform resource identifier
      /// \return Returns full path name to file
      public: std::string FindFileURI(const std::string &_uri);

      /// \brief Find a file in the set search paths
      /// \param[in] _filename Name of the file to find.
      /// \param[in] _searchLocalPath True to search in the current working
      /// directory.
      /// \return Returns full path name to file
      public: std::string FindFile(const std::string &_filename,
                                   bool _searchLocalPath = true);

      /// \brief Add colon delimited paths to plugins
      /// \param[in] _path the directory to add
      public: void AddPluginPaths(const std::string &_path);

      /// \brief clear out SystemPaths#pluginPaths
      public: void ClearPluginPaths();

      /// \brief add _suffix to the list of path search suffixes
      /// \param[in] _suffix The suffix to add
      public: void AddSearchPathSuffix(const std::string &_suffix);

      /// \brief Set the callback to use when ignition can't find a file.
      /// The callback should return a complete path to the requested file, or
      /// and empty string if the file was not found in the callback.
      /// \param[in] _cb The callback function.
      public: void SetFindFileCallback(
                  std::function<std::string (const std::string &)> _cb);

      /// \brief Set the callback to use when ignition can't find a file uri.
      /// The callback should return a complete path to the requested file, or
      /// and empty string if the file was not found in the callback.
      /// \param[in] _cb The callback function.
      public: void SetFindFileURICallback(
                  std::function<std::string (const std::string &)> _cb);

      /// \brief Private data pointer
      private: std::unique_ptr<SystemPathsPrivate> dataPtr;
    };
  }
}
#endif
