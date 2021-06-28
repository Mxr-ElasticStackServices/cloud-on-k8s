// Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
// or more contributor license agreements. Licensed under the Elastic License;
// you may not use this file except in compliance with the Elastic License.

package v1

import (
	"encoding/json"

	ucfg "github.com/elastic/go-ucfg"
)

// CfgOptions are config options for YAML config. Currently contains only support for dotted keys.
var CfgOptions = []ucfg.Option{ucfg.PathSep(".")}

// Config represents untyped YAML configuration.
// +kubebuilder:validation:Type=object
type Config struct {
	// Data holds the configuration keys and values.
	// This field exists to work around https://github.com/kubernetes-sigs/kubebuilder/issues/528
	Data map[string]interface{} `json:"-"`
}

// NewConfig constructs a Config with the given unstructured configuration data.
func NewConfig(cfg map[string]interface{}) Config {
	return Config{Data: cfg}
}

// MarshalJSON implements the Marshaler interface.
func (c *Config) MarshalJSON() ([]byte, error) {
	return json.Marshal(c.Data)
}

// UnmarshalJSON implements the Unmarshaler interface.
func (c *Config) UnmarshalJSON(data []byte) error {
	var out map[string]interface{}
	err := json.Unmarshal(data, &out)
	if err != nil {
		return err
	}
	c.Data = out
	return nil
}

// DeepCopyInto is an ~autogenerated~ deepcopy function, copying the receiver, writing into out. in must be non-nil.
// This exists here to work around https://github.com/kubernetes/code-generator/issues/50
func (c *Config) DeepCopyInto(out *Config) {
	bytes, err := json.Marshal(c.Data)
	if err != nil {
		// we assume that it marshals cleanly because otherwise the resource would not have been
		// created in the API server
		panic(err)
	}
	var clone map[string]interface{}
	err = json.Unmarshal(bytes, &clone)
	if err != nil {
		// we assume again optimistically because we just marshalled that the round trip works as well
		panic(err)
	}
	out.Data = clone
}
