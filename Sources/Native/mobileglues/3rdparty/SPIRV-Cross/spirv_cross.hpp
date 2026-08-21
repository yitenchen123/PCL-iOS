#ifndef SPIRV_CROSS_HPP
#define SPIRV_CROSS_HPP
#include "spirv.hpp"
#include "spirv_cfg.hpp"
#include "spirv_cross_parsed_ir.hpp"
namespace SPIRV_CROSS_NAMESPACE {
using namespace SPIRV_CROSS_SPV_HEADER_NAMESPACE;
struct Resource { ID id; TypeID type_id; TypeID base_type_id; std::string name; };
struct BuiltInResource { BuiltIn builtin; TypeID value_type_id; Resource resource; };
enum ResourceType { ResourceTypeUnknown=0, ResourceTypeUniformBuffer=1, ResourceTypeStorageBuffer=2, ResourceTypeStageInput=3, ResourceTypeStageOutput=4, ResourceTypeSubpassInput=5, ResourceTypeStorageImage=6, ResourceTypeSampledImage=7, ResourceTypeAtomicCounter=8, ResourceTypePushConstant=9, ResourceTypeSeparateImage=10, ResourceTypeSeparateSamplers=11, ResourceTypeAccelerationStructure=12, ResourceTypeRayQuery=13, ResourceTypeShaderRecordBuffer=14, ResourceTypeGLPlainUniform=15, ResourceTypeTensor=16 };
struct ShaderResources { SmallVector<Resource> uniform_buffers, storage_buffers, stage_inputs, stage_outputs, subpass_inputs, storage_images, sampled_images, atomic_counters, acceleration_structures, gl_plain_uniforms, tensors, push_constant_buffers, shader_record_buffers, separate_images, separate_samplers; SmallVector<BuiltInResource> builtin_inputs, builtin_outputs; };
struct CombinedImageSampler { VariableID combined_id, image_id, sampler_id; };
struct SpecializationConstant { ConstantID id; uint32_t constant_id; };
struct BufferRange { unsigned index; size_t offset, range; };
enum BufferPackingStandard { BufferPackingStd140, BufferPackingStd430, BufferPackingStd140EnhancedLayout, BufferPackingStd430EnhancedLayout, BufferPackingHLSLCbuffer, BufferPackingHLSLCbufferPackOffset, BufferPackingScalar, BufferPackingScalarEnhancedLayout };
struct EntryPoint { std::string name; ExecutionModel execution_model; };
class Compiler {
public: friend class CFG; friend class DominatorBuilder;
    explicit Compiler(std::vector<uint32_t> ir); Compiler(const uint32_t *ir, size_t word_count); explicit Compiler(const ParsedIR &ir); explicit Compiler(ParsedIR &&ir);
    virtual ~Compiler() = default;
    virtual std::string compile();
    const std::string &get_name(ID id) const;
    void set_decoration(ID id, Decoration decoration, uint32_t argument = 0); void set_decoration_string(ID id, Decoration decoration, const std::string &argument);
    void set_name(ID id, const std::string &name);
    const Bitset &get_decoration_bitset(ID id) const;
    bool has_decoration(ID id, Decoration decoration) const;
    uint32_t get_decoration(ID id, Decoration decoration) const; const std::string &get_decoration_string(ID id, Decoration decoration) const;
    void unset_decoration(ID id, Decoration decoration);
    const SPIRType &get_type(TypeID id) const; const SPIRType &get_type_from_variable(VariableID id) const;
    StorageClass get_storage_class(VariableID id) const;
    virtual const std::string get_fallback_name(ID id) const;
    virtual const std::string get_block_fallback_name(VariableID id) const;
    const std::string &get_member_name(TypeID id, uint32_t index) const;
    uint32_t get_member_decoration(TypeID id, uint32_t index, Decoration decoration) const; const std::string &get_member_decoration_string(TypeID id, uint32_t index, Decoration decoration) const;
    void set_member_name(TypeID id, uint32_t index, const std::string &name);
    const std::string &get_member_qualified_name(TypeID type_id, uint32_t index) const;
    const Bitset &get_member_decoration_bitset(TypeID id, uint32_t index) const;
    bool has_member_decoration(TypeID id, uint32_t index, Decoration decoration) const;
    void set_member_decoration(TypeID id, uint32_t index, Decoration decoration, uint32_t argument = 0); void set_member_decoration_string(TypeID id, uint32_t index, Decoration decoration, const std::string &argument);
    void unset_member_decoration(TypeID id, uint32_t index, Decoration decoration);
    virtual const std::string get_fallback_member_name(uint32_t index) const { return join("_", index); }
    SmallVector<BufferRange> get_active_buffer_ranges(VariableID id) const;
    size_t get_declared_struct_size(const SPIRType &struct_type) const;
    size_t get_declared_struct_size_runtime_array(const SPIRType &struct_type, size_t array_size) const;
    size_t get_declared_struct_member_size(const SPIRType &struct_type, uint32_t index) const;
    std::unordered_set<VariableID> get_active_interface_variables() const;
    void set_enabled_interface_variables(std::unordered_set<VariableID> active_variables);
    ShaderResources get_shader_resources() const; ShaderResources get_shader_resources(const std::unordered_set<VariableID> &active_variables) const;
    void set_remapped_variable_state(VariableID id, bool remap_enable); bool get_remapped_variable_state(VariableID id) const;
    void set_subpass_input_remapped_components(VariableID id, uint32_t components); uint32_t get_subpass_input_remapped_components(VariableID id) const;
    SmallVector<EntryPoint> get_entry_points_and_stages() const;
    void set_entry_point(const std::string &entry, ExecutionModel execution_model);
    void rename_entry_point(const std::string &old_name, const std::string &new_name, ExecutionModel execution_model);
    const SPIREntryPoint &get_entry_point(const std::string &name, ExecutionModel execution_model) const;
    SPIREntryPoint &get_entry_point(const std::string &name, ExecutionModel execution_model);
    const std::string &get_cleansed_entry_point_name(const std::string &name, ExecutionModel execution_model) const;
    void update_active_builtins(); bool has_active_builtin(BuiltIn builtin, StorageClass storage) const;
    const Bitset &get_execution_mode_bitset() const;
    void unset_execution_mode(ExecutionMode mode); void set_execution_mode(ExecutionMode mode, uint32_t arg0 = 0, uint32_t arg1 = 0, uint32_t arg2 = 0);
    uint32_t get_execution_mode_argument(ExecutionMode mode, uint32_t index = 0) const;
    ExecutionModel get_execution_model() const;
    bool is_tessellation_shader() const; bool is_tessellating_triangles() const;
    uint32_t get_work_group_size_specialization_constants(SpecializationConstant &x, SpecializationConstant &y, SpecializationConstant &z) const;
};
}
#endif
