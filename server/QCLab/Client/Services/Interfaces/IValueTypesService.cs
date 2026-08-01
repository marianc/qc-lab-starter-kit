using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IValueTypesService
    {
        Task<List<ValueTypeDto>> GetAllValueTypes();
    }
}